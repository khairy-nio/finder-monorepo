const express =require('express');
const Router = express.Router();
const userRoute=require('./user.route');
const adminRoute=require('./admin.route');
const PostRoute=require('./post.route');
const MatchingRoute = require('./matching.route');
const ContactReqRoute = require('./contactReq.route');
const ChatRoute = require('./chat.route');
const ReportRoute = require('./report.route');
const NotificationRoute = require('./notification.route');
const response = require('../utils/response.util');

Router.use('/user',userRoute);
Router.use('/admin',adminRoute);
Router.use('/post',PostRoute);
Router.use('/match', MatchingRoute);
Router.use('/contact-request', ContactReqRoute);
Router.use('/chat', ChatRoute);
Router.use('/report', ReportRoute);
Router.use('/notification', NotificationRoute);
Router.get('/status', (req, res) => {
    return response.Success(res, 'API working correctly', { status: 'ok' }, 200);
});

Router.get('/health', (req, res) => {
    return response.Success(res, 'Service healthy', { status: 'ok' }, 200);
});
module.exports=Router;