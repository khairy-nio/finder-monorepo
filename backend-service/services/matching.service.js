const postRepo = require('../Repository/post.repo');
const AIService = require('../config/ai.config');
const pineconeIndex = require('../config/pinecone.config');
const { normalizeLocation } = require('../utils/normalization.util');

const MAX_DISTANCE_KM = 40; // 40km radius for local matching

class MatchingService {

    /**
     * Calculate distance between two coordinates using Haversine formula
     * @returns {number} Distance in kilometers
     */
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371; // Earth radius in km
        const dLat = this.toRad(lat2 - lat1);
        const dLon = this.toRad(lon2 - lon1);
        
        const a = 
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    toRad(degrees) {
        return degrees * (Math.PI / 180);
    }

    async checkMatch(imageUrl, type, category, country, state, city, area, latitude, longitude) {
        try {
            // ==========================================
            // VALIDATION
            // ==========================================
            if (!imageUrl || !type) {
                return {
                    success: false,
                    message: 'Image URL and Post Type are required for matching'
                };
            }

            const oppositeType = type === 'lost' ? 'found' : 'lost';

            // ==========================================
            // STEP 1: Fetch Candidate Posts (with Progressive Fallbacks)
            // ==========================================
            console.log('Step 1: Fetching candidate posts with fallbacks...');
            
            // Normalize inputs for consistent searching
            const normCountry = normalizeLocation(country);
            const normState = state ? normalizeLocation(state) : null;
            const normCity = city ? normalizeLocation(city) : null;
            const normArea = area ? normalizeLocation(area) : null;
            const normCategory = category ? normalizeLocation(category) : null;

            console.log(`[MatchingService] Normalized inputs: city="${normCity}", area="${normArea}", category="${normCategory}"`);

            let appliedState = normState;
            let appliedCity = normCity;
            let appliedArea = normArea;
            let appliedCategory = normCategory;

            console.log(`[MatchingService] Searching candidates. Input filters (normalized): country=${normCountry}, state=${normState}, city=${normCity}, area=${normArea}, category=${normCategory}`);

            let candidatePosts = await postRepo.getFilteredPosts({
                type: oppositeType,
                status: 'active',
                country: normCountry || null,
                state: normState || null,
                city: normCity || null,
                area: normArea || null,
                category: normCategory || null,
                limit: 500,
                offset: 0
            });

            // Fallback 1: Relax Area
            if (candidatePosts.count === 0 && normArea) {
                console.log(`[MatchingService] No candidates in area "${normArea}". Retrying without area...`);
                appliedArea = null;
                candidatePosts = await postRepo.getFilteredPosts({
                    type: oppositeType,
                    status: 'active',
                    country: normCountry || null,
                    state: normState || null,
                    city: normCity || null,
                    category: normCategory || null,
                    limit: 500,
                    offset: 0
                });
            }

            // Fallback 2: Relax State
            if (candidatePosts.count === 0 && normState) {
                console.log(`[MatchingService] No candidates in state "${normState}". Retrying without state...`);
                appliedState = null;
                candidatePosts = await postRepo.getFilteredPosts({
                    type: oppositeType,
                    status: 'active',
                    country: normCountry || null,
                    city: normCity || null,
                    category: normCategory || null,
                    limit: 500,
                    offset: 0
                });
            }

            // Fallback 3: Relax Category
            if (candidatePosts.count === 0 && normCategory && normCategory !== 'other') {
                console.log(`[MatchingService] No candidates in category "${normCategory}". Retrying without category...`);
                appliedCategory = null;
                candidatePosts = await postRepo.getFilteredPosts({
                    type: oppositeType,
                    status: 'active',
                    country: normCountry || null,
                    city: normCity || null,
                    limit: 500,
                    offset: 0
                });
            }

            let nearbyPosts = candidatePosts.rows;

            // Early exit if still no candidates found
            if (candidatePosts.count === 0) {
                console.log(`No ${oppositeType} posts in city-wide query for ${normCity || normCountry}. Skipping embedding.`);
                return {
                    success: true,
                    message: `No ${oppositeType} items found in ${normCity || normCountry}`,
                    data: [],
                    count: 0
                };
            }

            console.log(`Found ${candidatePosts.count} candidate ${oppositeType} posts in database.`);

            // Apply distance filter if coordinates provided
            if (latitude && longitude) {
                const latFloat = parseFloat(latitude);
                const lonFloat = parseFloat(longitude);
                
                if (!isNaN(latFloat) && !isNaN(lonFloat)) {
                    nearbyPosts = candidatePosts.rows.filter(post => {
                        if (!post.latitude || !post.longitude) return false;
                        
                        const postLat = parseFloat(post.latitude);
                        const postLon = parseFloat(post.longitude);
                        
                        if (isNaN(postLat) || isNaN(postLon)) return false;
                        
                        const distance = this.calculateDistance(
                            latFloat,
                            lonFloat,
                            postLat,
                            postLon
                        );
                        
                        post.dataValues.distance_km = Math.round(distance * 10) / 10;
                        return distance <= MAX_DISTANCE_KM;
                    });

                    console.log(`${nearbyPosts.length} posts within ${MAX_DISTANCE_KM}km radius filter`);

                    // Resilient Fallback: If strict distance filter leaves 0 candidates (e.g. wrong input coords),
                    // fall back to all candidate posts in the city rather than returning an empty match list.
                    if (nearbyPosts.length === 0) {
                        console.log(`[MatchingService] Distance filter pruned all candidates. Falling back to all city posts.`);
                        nearbyPosts = candidatePosts.rows;
                    }
                }
            }

            // ==========================================
            // STEP 2: Generate Embedding (Only if candidates exist!)
            // ==========================================
            console.log('Step 2: Generating image embedding...');
            const imagevector = await AIService.generateEmbedding(imageUrl);

            // ==========================================
            // STEP 3: Vector Similarity Search (Focused on nearby posts)
            // ==========================================
            const candidateIds = nearbyPosts.map(p => p.id);
            
            console.log(`Step 3: Searching ${candidateIds.length} vectors in Pinecone...`);

            // Build Pinecone filter dynamically aligned with database candidate records
            const samplePost = nearbyPosts[0];
            
            // RELAXED: Removed moderation_status as it may be missing in older Pinecone records
            const pineconeFilter = {
                post_type: oppositeType,
                status: 'active'
            };

            // Use the actual database values (normalized) to ensure query matching
            if (samplePost.country) pineconeFilter.country = normalizeLocation(samplePost.country);
            if (appliedState && samplePost.state) pineconeFilter.state = normalizeLocation(samplePost.state);
            if (appliedCity && samplePost.city) pineconeFilter.city = normalizeLocation(samplePost.city);
            if (appliedArea && samplePost.area) pineconeFilter.area = normalizeLocation(samplePost.area);
            if (appliedCategory && samplePost.category) pineconeFilter.category = normalizeLocation(samplePost.category);

            console.log(`[MatchingService] Pinecone query for ${oppositeType} in ${pineconeFilter.city || pineconeFilter.country}`);
            console.log('[MatchingService] Pinecone filter:', JSON.stringify(pineconeFilter));

            const matchResults = await pineconeIndex.query({
                vector: imagevector,
                topK: Math.min(nearbyPosts.length + 20, 100), // Search more candidates for better visual matches
                includeMetadata: true,
                filter: pineconeFilter
            });

            console.log(`[MatchingService] Pinecone returned ${matchResults.matches?.length || 0} raw matches.`);
            
            if (!matchResults.matches || matchResults.matches.length === 0) {
                // FALLBACK: If filtering caused 0 results, try relaxing city/area filters in Pinecone too
                console.log('[MatchingService] Zero matches with strict filters. Retrying with relaxed Pinecone filter (country only)...');
                const relaxedFilter = {
                    post_type: oppositeType,
                    status: 'active',
                    country: normalizeLocation(samplePost.country)
                };
                
                const relaxedResults = await pineconeIndex.query({
                    vector: imagevector,
                    topK: 20,
                    includeMetadata: true,
                    filter: relaxedFilter
                });
                
                matchResults.matches = relaxedResults.matches || [];
                console.log(`[MatchingService] Relaxed Pinecone search returned ${matchResults.matches.length} matches.`);
            }

            if (matchResults.matches && matchResults.matches.length > 0) {
                matchResults.matches.forEach((m, idx) => {
                    const isCandidate = nearbyPosts.some(p => p.id === m.id);
                    console.log(`  Match ${idx + 1}: ID=${m.id}, Score=${m.score.toFixed(4)}, In SQL Candidates=${isCandidate}, City=${m.metadata?.city}`);
                });
            }


            if (!matchResults.matches || matchResults.matches.length === 0) {
                return {
                    success: true,
                    message: 'No visually similar items found',
                    data: [],
                    count: 0
                };
            }

            // ==========================================
            // STEP 4: Merge Results (SQL + Vector + Distance)
            // ==========================================
            const enrichedResults = matchResults.matches
                .map(match => {
                    const post = nearbyPosts.find(p => p.id === match.id);
                    if (!post) return null;

                    return {
                        ...post.toJSON(),
                        similarity_score: Math.round(match.score * 100) / 100,
                        match_percentage: Math.round(match.score * 100),
                        distance_km: post.dataValues.distance_km || null
                    };
                })
                .filter(Boolean)
                .filter(res => res.match_percentage >= 75);

            // Sort: High similarity first, then close distance
            enrichedResults.sort((a, b) => {
                const scoreDiff = b.similarity_score - a.similarity_score;
                if (Math.abs(scoreDiff) > 0.05) return scoreDiff;
                return (a.distance_km || 999) - (b.distance_km || 999);
            });

            return {
                success: true,
                message: `Found ${enrichedResults.length} potential matches`,
                data: enrichedResults,
                count: enrichedResults.length,
                metadata: {
                    searched_area: area || city || state || country,
                    total_candidates: candidatePosts.count,
                    within_radius: nearbyPosts.length,
                    visual_matches: enrichedResults.length
                }
            };

        } catch (err) {
            console.error('Matching error:', err);
            return {
                success: false,
                message: 'Failed to process match request'
            };
        }
    }
}

module.exports = new MatchingService();
