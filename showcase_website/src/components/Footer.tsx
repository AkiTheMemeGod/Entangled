import { motion } from 'framer-motion'
import { Github, Download, Mail, MessageCircle, Heart } from 'lucide-react'

const footerLinks = [
  { name: 'GitHub', href: 'https://github.com/AkiTheMemeGod/Entangled', icon: Github },
  { name: 'Download', href: '#download', icon: Download },
  { name: 'Contact', href: 'mailto:contact@entangled.app', icon: Mail },
]

export default function Footer() {
  const currentYear = new Date().getFullYear()

  return (
    <footer id="contact" className="relative z-10 border-t border-border bg-background py-12">
      <div className="mx-auto max-w-7xl px-8">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row">
          {/* Logo and tagline */}
          <motion.div
            className="text-center md:text-left"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
          >
            <div className="mb-2 flex items-center justify-center gap-2 md:justify-start">
              <MessageCircle className="h-5 w-5 text-muted-foreground" />
              <span className="font-display text-xl tracking-tight text-foreground">
                Entangled<sup className="text-xs">®</sup>
              </span>
            </div>
            <p className="text-sm text-muted-foreground">Where conversations come alive.</p>
          </motion.div>

          {/* Navigation links */}
          <motion.nav
            className="flex flex-wrap items-center justify-center gap-6"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1, duration: 0.5 }}
          >
            {footerLinks.map((link) => (
              <a
                key={link.name}
                href={link.href}
                target={link.href.startsWith('http') ? '_blank' : undefined}
                rel={link.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                className="flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
              >
                <link.icon className="h-4 w-4" />
                <span>{link.name}</span>
              </a>
            ))}
          </motion.nav>
        </div>

        {/* Divider */}
        <div className="my-8 h-px bg-gradient-to-r from-transparent via-border to-transparent" />

        {/* Bottom section */}
        <motion.div
          className="flex flex-col items-center gap-4 text-center"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2, duration: 0.5 }}
        >
          <p className="flex items-center gap-1 text-sm text-muted-foreground">
            Made with <Heart className="h-4 w-4 fill-red-400 text-red-400" /> by the Entangled Team
          </p>
          <p className="text-xs text-muted-foreground/50">
            &copy; {currentYear} Entangled. All rights reserved.
          </p>
        </motion.div>
      </div>
    </footer>
  )
}
