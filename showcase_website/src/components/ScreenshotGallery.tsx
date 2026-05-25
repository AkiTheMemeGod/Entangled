import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight, Smartphone, X } from 'lucide-react'

const screenshots = [
  {
    src: '/images/homescreen.png',
    title: 'Beautiful Home Screen',
    description: 'Your conversations, organized and accessible. Quick access to recent chats with a clean, modern interface.'
  },
  {
    src: '/images/chatting with friend 1.png',
    title: 'Real-Time Messaging',
    description: 'Send messages instantly with typing indicators and read receipts. Know when your message has been seen.'
  },
  {
    src: '/images/chatting with friend 1 with emoji reaction and voice note and images.png',
    title: 'Rich Media & Reactions',
    description: 'Share photos, send voice notes, and react with emojis. Full-featured messaging for every situation.'
  },
  {
    src: '/images/chat_screen and in app notification.png',
    title: 'Smart Notifications',
    description: 'Stay informed without being overwhelmed. In-app notifications keep you updated in real-time.'
  },
  {
    src: '/images/friend_request.png',
    title: 'Friend Requests',
    description: 'Connect with friends securely. Send and manage connection requests with full control over your network.'
  },
  {
    src: '/images/login_page.png',
    title: 'Secure Login',
    description: 'Quick and secure access to your account. Simple authentication that keeps your data protected.'
  },
  {
    src: '/images/settings page and multi color theme switcher.png',
    title: 'Themes & Settings',
    description: 'Personalize your experience with multiple color themes. Customize notifications, privacy, and appearance.'
  },
  {
    src: '/images/profile page.png',
    title: 'Profile Customization',
    description: 'Create your unique profile with custom information. Make it truly yours with personalized details.'
  }
]

export default function ScreenshotGallery() {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [isModalOpen, setIsModalOpen] = useState(false)

  const nextSlide = () => {
    setCurrentIndex((prev) => (prev + 1) % screenshots.length)
  }

  const prevSlide = () => {
    setCurrentIndex((prev) => (prev - 1 + screenshots.length) % screenshots.length)
  }

  const openModal = (index: number) => {
    setCurrentIndex(index)
    setIsModalOpen(true)
  }

  return (
    <>
      <section id="screenshots" className="relative z-10 bg-background py-24">
        <div className="mx-auto max-w-7xl px-8">
          {/* Section Header */}
          <motion.div
            className="mb-16 text-center"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-border px-4 py-1.5">
              <Smartphone className="h-4 w-4 text-muted-foreground" />
              <span className="text-xs text-muted-foreground">App Preview</span>
            </div>
            <h2
              className="font-display text-4xl font-normal tracking-tight text-foreground sm:text-5xl"
              style={{ fontFamily: "'Instrument Serif', serif" }}
            >
              See <em className="not-italic text-muted-foreground">Entangled</em> in action
            </h2>
            <p className="mx-auto mt-4 max-w-xl text-muted-foreground">
              Explore the features that make Entangled the preferred choice for private, secure messaging on Android.
            </p>
          </motion.div>

          {/* Main Carousel */}
          <motion.div
            className="relative mx-auto max-w-4xl"
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            {/* Phone Frame */}
            <div className="relative mx-auto w-full max-w-[360px]">
              {/* Phone Bezel */}
              <div className="relative rounded-[3rem] border-4 border-border bg-secondary p-3 shadow-2xl">
                {/* Notch */}
                <div className="absolute left-1/2 top-0 z-20 h-6 w-32 -translate-x-1/2 rounded-b-2xl bg-secondary" />
                
                {/* Screen */}
                <div className="relative aspect-[9/19.5] overflow-hidden rounded-[2.5rem] bg-background">
                  <AnimatePresence mode="wait">
                    <motion.img
                      key={currentIndex}
                      src={screenshots[currentIndex].src}
                      alt={screenshots[currentIndex].title}
                      className="h-full w-full object-cover cursor-pointer"
                      initial={{ opacity: 0, x: 100 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -100 }}
                      transition={{ duration: 0.3 }}
                      onClick={() => openModal(currentIndex)}
                    />
                  </AnimatePresence>
                </div>
              </div>

              {/* Navigation Arrows */}
              <button
                onClick={prevSlide}
                className="liquid-glass absolute left-0 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full p-3 transition-transform hover:scale-110"
                aria-label="Previous screenshot"
              >
                <ChevronLeft className="h-5 w-5 text-foreground" />
              </button>
              <button
                onClick={nextSlide}
                className="liquid-glass absolute right-0 top-1/2 -translate-y-1/2 translate-x-1/2 rounded-full p-3 transition-transform hover:scale-110"
                aria-label="Next screenshot"
              >
                <ChevronRight className="h-5 w-5 text-foreground" />
              </button>
            </div>

            {/* Caption */}
            <AnimatePresence mode="wait">
              <motion.div
                key={currentIndex}
                className="mt-8 text-center"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.3 }}
              >
                <h3 className="text-lg font-medium text-foreground">
                  {screenshots[currentIndex].title}
                </h3>
                <p className="mt-2 text-sm text-muted-foreground">
                  {screenshots[currentIndex].description}
                </p>
              </motion.div>
            </AnimatePresence>

            {/* Thumbnail Navigation */}
            <div className="mt-8 flex justify-center gap-2">
              {screenshots.map((_, index) => (
                <button
                  key={index}
                  onClick={() => setCurrentIndex(index)}
                  className={`h-2 rounded-full transition-all ${
                    index === currentIndex
                      ? 'w-8 bg-foreground'
                      : 'w-2 bg-muted-foreground/30 hover:bg-muted-foreground/50'
                  }`}
                  aria-label={`Go to screenshot ${index + 1}`}
                />
              ))}
            </div>
          </motion.div>

          {/* Grid of All Screenshots */}
          <motion.div
            className="mt-20 grid gap-4 sm:grid-cols-2 lg:grid-cols-5"
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            {screenshots.slice(0, 5).map((screenshot, index) => (
              <motion.button
                key={index}
                onClick={() => openModal(index)}
                className="group relative aspect-[9/16] overflow-hidden rounded-xl border border-border bg-secondary"
                whileHover={{ scale: 1.02 }}
                transition={{ duration: 0.2 }}
              >
                <img
                  src={screenshot.src}
                  alt={screenshot.title}
                  className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-background/80 to-transparent opacity-0 transition-opacity group-hover:opacity-100" />
                <div className="absolute bottom-0 left-0 right-0 p-3 text-left opacity-0 transition-opacity group-hover:opacity-100">
                  <p className="text-xs font-medium text-foreground">{screenshot.title}</p>
                </div>
              </motion.button>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <motion.div
            className="fixed inset-0 z-50 flex items-center justify-center bg-background/95 backdrop-blur-sm p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsModalOpen(false)}
          >
            <motion.div
              className="relative max-w-5xl w-full"
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
            >
              {/* Close Button */}
              <button
                onClick={() => setIsModalOpen(false)}
                className="absolute -top-12 right-0 rounded-full p-2 text-muted-foreground transition-colors hover:text-foreground"
              >
                <X className="h-6 w-6" />
              </button>

              <div className="flex flex-col items-center gap-6 lg:flex-row lg:items-start">
                {/* Large Screenshot */}
                <div className="relative max-w-sm overflow-hidden rounded-3xl border-4 border-border bg-secondary">
                  <img
                    src={screenshots[currentIndex].src}
                    alt={screenshots[currentIndex].title}
                    className="h-auto w-full"
                  />
                </div>

                {/* Info Panel */}
                <div className="flex-1 text-center lg:text-left">
                  <h3 className="text-2xl font-display text-foreground">
                    {screenshots[currentIndex].title}
                  </h3>
                  <p className="mt-4 text-muted-foreground">
                    {screenshots[currentIndex].description}
                  </p>
                  
                  {/* Navigation */}
                  <div className="mt-8 flex items-center justify-center gap-4 lg:justify-start">
                    <button
                      onClick={prevSlide}
                      className="liquid-glass rounded-full p-3 transition-transform hover:scale-110"
                    >
                      <ChevronLeft className="h-5 w-5" />
                    </button>
                    <span className="text-sm text-muted-foreground">
                      {currentIndex + 1} / {screenshots.length}
                    </span>
                    <button
                      onClick={nextSlide}
                      className="liquid-glass rounded-full p-3 transition-transform hover:scale-110"
                    >
                      <ChevronRight className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}
