import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown, HelpCircle } from 'lucide-react'

const faqs = [
  {
    question: 'What is Entangled and how does it work?',
    answer: 'Entangled is a free, open-source messaging app for Android that prioritizes your privacy. It works like any modern chat app — you can send text messages, voice notes, images, and reactions. The difference is that we do not collect your data, show ads, or track your behavior. Your conversations are truly yours.'
  },
  {
    question: 'Is Entangled really free? Are there any hidden costs?',
    answer: 'Entangled is 100% free, forever. There are no subscription fees, no in-app purchases, and no hidden costs. We are funded entirely by community donations and volunteer contributions. Our commitment is to keep messaging accessible to everyone.'
  },
  {
    question: 'How secure and private is Entangled?',
    answer: 'Security is our top priority. Entangled does not store your messages on our servers — all data is synchronized through Firebase Firestore with end-to-end encryption. We do not sell your data, we do not show you ads based on your conversations, and we cannot read your messages. Your privacy is guaranteed by our open-source code, which anyone can audit.'
  },
  {
    question: 'What Android version do I need to run Entangled?',
    answer: 'Entangled requires Android 8.0 (API level 26) or higher. This covers approximately 95% of active Android devices worldwide. We recommend keeping your device updated to the latest Android version for the best security and performance.'
  },
  {
    question: 'Can I use Entangled on iOS or desktop?',
    answer: 'Currently, Entangled is only available for Android devices. We are actively developing an iOS version and exploring desktop clients for Windows, macOS, and Linux. Follow our GitHub repository for updates on cross-platform support.'
  },
  {
    question: 'How do I add friends and start chatting?',
    answer: 'Adding friends is simple. You can search for users by their username or email address. Send a friend request, and once accepted, you can start messaging immediately. There are no phone number requirements, keeping your contact information private.'
  },
  {
    question: 'Is the source code really open? Can I contribute?',
    answer: 'Yes! Entangled is fully open-source under the MIT License. You can view, fork, and contribute to our codebase on GitHub. We welcome bug reports, feature suggestions, and code contributions from developers of all skill levels. Check out our contributing guide to get started.'
  },
  {
    question: 'How can I report bugs or request new features?',
    answer: 'We use GitHub Issues to track bugs and feature requests. Visit our repository and open a new issue with a detailed description. For security vulnerabilities, please email us directly at security@entangled.app instead of posting publicly.'
  }
]

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0)

  const toggleQuestion = (index: number) => {
    setOpenIndex(openIndex === index ? null : index)
  }

  return (
    <section id="faq" className="relative z-10 bg-background py-24">
      <div className="mx-auto max-w-4xl px-8">
        {/* Section Header */}
        <motion.div
          className="mb-16 text-center"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-border px-4 py-1.5">
            <HelpCircle className="h-4 w-4 text-muted-foreground" />
            <span className="text-xs text-muted-foreground">Common Questions</span>
          </div>
          <h2
            className="font-display text-4xl font-normal tracking-tight text-foreground sm:text-5xl"
            style={{ fontFamily: "'Instrument Serif', serif" }}
          >
            Frequently <em className="not-italic text-muted-foreground">Asked</em> Questions
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-muted-foreground">
            Everything you need to know about Entangled. Cannot find what you are looking for? 
            Reach out to us on GitHub.
          </p>
        </motion.div>

        {/* FAQ Items */}
        <motion.div
          className="space-y-4"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          {faqs.map((faq, index) => (
            <div
              key={index}
              className="overflow-hidden rounded-xl border border-border bg-secondary/20 transition-colors hover:bg-secondary/30"
            >
              <button
                onClick={() => toggleQuestion(index)}
                className="flex w-full items-center justify-between p-6 text-left"
              >
                <span className="pr-4 text-lg font-medium text-foreground">
                  {faq.question}
                </span>
                <motion.div
                  animate={{ rotate: openIndex === index ? 180 : 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <ChevronDown className="h-5 w-5 flex-shrink-0 text-muted-foreground" />
                </motion.div>
              </button>
              <AnimatePresence initial={false}>
                {openIndex === index && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.3, ease: 'easeInOut' }}
                  >
                    <div className="border-t border-border px-6 pb-6 pt-2">
                      <p className="leading-relaxed text-muted-foreground">
                        {faq.answer}
                      </p>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ))}
        </motion.div>

        {/* CTA */}
        <motion.div
          className="mt-12 text-center"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
        >
          <p className="text-muted-foreground">
            Still have questions?{' '}
            <a
              href="https://github.com/AkiTheMemeGod/Entangled/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="text-foreground underline underline-offset-4 transition-colors hover:text-muted-foreground"
            >
              Open an issue on GitHub
            </a>
          </p>
        </motion.div>
      </div>
    </section>
  )
}
