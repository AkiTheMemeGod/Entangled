import { motion } from 'framer-motion'
import { Download, Github, Shield, Lock, Sparkles } from 'lucide-react'

export default function Hero() {
  return (
    <section className="relative min-h-screen">
      {/* Video Background */}
      <div className="absolute inset-0 z-0">
        <video
          autoPlay
          loop
          muted
          playsInline
          className="h-full w-full object-cover"
          poster="https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=1920&q=80"
        >
          <source
            src="https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20260314_131748_f2ca2a28-fed7-44c8-b9a9-bd9acdd5ec31.mp4"
            type="video/mp4"
          />
        </video>
        {/* Subtle overlay for better text readability */}
        <div className="absolute inset-0 bg-background/70" />
      </div>

      {/* Hero Content */}
      <div className="relative z-10 flex min-h-screen flex-col items-center justify-center px-6 pb-40 pt-32 text-center">
        {/* Trust Badge */}
        <motion.div
          className="mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-background/50 px-4 py-1.5 backdrop-blur-sm"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1, duration: 0.6 }}
        >
          <Shield className="h-3.5 w-3.5 text-green-400" />
          <span className="text-xs text-muted-foreground">Open Source & Privacy First</span>
        </motion.div>

        {/* Main Headline - SEO Optimized */}
        <motion.h1
          className="animate-fade-rise max-w-5xl font-display text-5xl font-normal leading-[0.95] tracking-[-2.46px] text-foreground sm:text-6xl md:text-7xl lg:text-8xl"
          style={{ fontFamily: "'Instrument Serif', serif" }}
        >
          Messaging that{' '}
          <em className="not-italic text-muted-foreground">respects</em> your privacy.
        </motion.h1>

        {/* Value Proposition - Benefit focused */}
        <motion.p
          className="animate-fade-rise-delay mt-8 max-w-2xl text-lg leading-relaxed text-muted-foreground sm:text-xl"
        >
          Entangled is a free, open-source Android messaging app. No ads, no tracking, 
          no corporate surveillance — just pure, secure communication with the people who matter.
        </motion.p>

        {/* Key Benefits Row */}
        <motion.div
          className="animate-fade-rise-delay mt-8 flex flex-wrap items-center justify-center gap-6 text-sm text-muted-foreground"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.5 }}
        >
          <span className="flex items-center gap-1.5">
            <Lock className="h-4 w-4" />
            End-to-End Encryption
          </span>
          <span className="flex items-center gap-1.5">
            <Sparkles className="h-4 w-4" />
            100% Free Forever
          </span>
          <span className="flex items-center gap-1.5">
            <Github className="h-4 w-4" />
            Fully Open Source
          </span>
        </motion.div>

        {/* CTA Buttons */}
        <motion.div
          className="animate-fade-rise-delay-2 mt-12 flex flex-col items-center gap-4 sm:flex-row"
        >
          <a
            href="#download"
            className="liquid-glass group inline-flex items-center gap-3 rounded-full px-10 py-5 text-base font-medium text-foreground transition-transform"
          >
            <motion.div
              animate={{ y: [0, -3, 0] }}
              transition={{ duration: 1.5, repeat: Infinity }}
            >
              <Download className="h-5 w-5" />
            </motion.div>
            Download APK Free
          </a>
          <a
            href="https://github.com/AkiTheMemeGod/Entangled"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 rounded-full px-8 py-5 text-base text-muted-foreground transition-colors hover:text-foreground"
          >
            <Github className="h-5 w-5" />
            View Source Code
          </a>
        </motion.div>

        {/* Social Proof */}
        <motion.p
          className="animate-fade-rise-delay-2 mt-6 text-xs text-muted-foreground/60"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.9, duration: 0.5 }}
        >
          Trusted by 1,000+ users worldwide · Available on GitHub · Android 8.0+
        </motion.p>
      </div>

      {/* Scroll indicator */}
      <motion.div
        className="absolute bottom-8 left-1/2 z-10 -translate-x-1/2"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2, duration: 0.5 }}
      >
        <motion.div
          animate={{ y: [0, 8, 0] }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          className="h-12 w-6 rounded-full border-2 border-border p-1"
        >
          <div className="h-2 w-full rounded-full bg-foreground/50" />
        </motion.div>
      </motion.div>
    </section>
  )
}
