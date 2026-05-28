import { BrowserRouter } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { QueryProvider } from './providers/QueryProvider';
import { AuthProvider } from './providers/AuthProvider';
import { ThemeModeProvider } from './providers/ThemeModeProvider';
import AppRoutes from './routes/AppRoutes';

function App() {
  return (
    <ThemeModeProvider>
      <Toaster position='top-right' />
      <QueryProvider>
        <AuthProvider>
          <BrowserRouter>
            <AppRoutes />
          </BrowserRouter>
        </AuthProvider>
      </QueryProvider>
    </ThemeModeProvider>
  );
}

export default App;

