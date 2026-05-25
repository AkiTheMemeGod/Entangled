import { motion } from 'framer-motion'
import {
  MessageCircle,
  Smile,
  Mic,
  Bell,
  Palette,
  ImageIcon,
  Zap,
  Shield,
  Code,
} from 'lucide-react'

const features = [
  {
    icon: MessageCircle,
    title: 'Lightning-Fast Messaging',
    description: 'Experience instant message delivery with real-time sync. See when friends are typing and know exactly when your messages are read.',
    highlight: 'Zero latency',
  },
  {
    icon: Shield,
    title: 'Privacy by Design',
    description: 'Your conversations stay private. No data mining, no targeted ads, no corporate surveillance. Your data belongs to you alone.',
    highlight: '100% Private',
  },
  {
    icon: Mic,
    title: 'Crystal-Clear Voice Notes',
    description: 'Send voice messages with studio-quality audio. Perfect for when typing is inconvenient or when tone matters.',
    highlight: 'HD Audio',
  },
  {
    icon: Smile,
    title: 'Expressive Reactions',
    description: 'React to any message with a full range of emojis. Sometimes a reaction says more than words ever could.',
    highlight: 'Quick React',
  },
  {
    icon: ImageIcon,
    title: 'Seamless Media Sharing',
    description: 'Share photos, screenshots, and files without compression. Your images arrive in full quality, every time.',
    highlight: 'No Compression',
  },
  {
    icon: Palette,
    title: 'Beautiful Themes',
    description: 'Personalize your experience with multiple stunning color themes. From dark mode to vibrant accents, make it yours.',
    highlight: 'Customizable',
  },
  {
    icon: Bell,
    title: 'Intelligent Notifications',
    description: 'Smart alerts keep you informed without overwhelming you. Customize notification preferences per conversation.',
    highlight: 'Smart Alerts',
  },
  {
    icon: Code,
    title: 'Open Source Forever',
    description: 'Built on transparency. Our entire codebase is open for review, contribution, and audit. Trust through verification.',
    highlight: 'Fully Open',
  },
]

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
    },
  },
}

const cardVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
      ease: [0.22, 1, 0.36, 1],
    },
  },
}

export default function Features() {
  return (
    <section id="features" className="relative z-10 bg-background py-32">
      <div className="mx-auto max-w-7xl px-8">
        {/* Section header */}
        <motion.div
          className="mb-20 text-center"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          <motion.div
            className="mb-4 inline-flex items-center gap-2 rounded-full border border-border px-4 py-1.5"
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1, duration: 0.4 }}
          >
            <Zap className="h-4 w-4 text-muted-foreground" />
            <span className="text-xs text-muted-foreground">Why Choose Entangled</span>
          </motion.div>
          <h2
            className="font-display text-4xl font-normal tracking-tight text-foreground sm:text-5xl md:text-6xl"
            style={{ fontFamily: "'Instrument Serif', serif" }}
          >
            Built for <em className="not-italic text-muted-foreground">privacy</em>, designed for you
          </h2>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-muted-foreground">
            Every feature in Entangled is crafted to give you a superior messaging experience 
            while respecting your privacy. No compromises, no hidden costs.
          </p>
        </motion.div>

        {/* Features grid */}
        <motion.div
          className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
        >
          {features.map((feature) => (
            <motion.div
              key={feature.title}
              variants={cardVariants}
              whileHover={{ y: -4 }}
              transition={{ duration: 0.2 }}
              className="group"
            >
              <div className="relative h-full overflow-hidden rounded-2xl border border-border bg-secondary/30 p-6 transition-colors hover:bg-secondary/50">
                {/* Highlight Badge */}
                <span className="absolute right-4 top-4 text-[10px] uppercase tracking-wider text-muted-foreground/60">
                  {feature.highlight}
                </span>

                {/* Icon */}
                <div className="mb-4 inline-flex rounded-xl bg-background/50 p-3 transition-transform group-hover:scale-110">
                  <feature.icon className="h-5 w-5 text-foreground" />
                </div>

                {/* Title */}
                <h3 className="mb-2 text-lg font-medium text-foreground">
                  {feature.title}
                </h3>

                {/* Description */}
                <p className="text-sm leading-relaxed text-muted-foreground">
                  {feature.description}
                </p>

                {/* Bottom accent */}
                <div className="absolute bottom-0 left-0 h-[2px] w-0 bg-gradient-to-r from-foreground/50 to-transparent transition-all duration-300 group-hover:w-full" />
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}
