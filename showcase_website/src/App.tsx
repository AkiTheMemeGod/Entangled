import Navigation from './components/Navigation'
import Hero from './components/Hero'
import ScreenshotGallery from './components/ScreenshotGallery'
import Features from './components/Features'
import FAQ from './components/FAQ'
import Download from './components/Download'
import Footer from './components/Footer'

function App() {
  return (
    <div className="min-h-screen bg-background">
      <Navigation />
      <Hero />
      <ScreenshotGallery />
      <Features />
      <FAQ />
      <Download />
      <Footer />
    </div>
  )
}

export default App
