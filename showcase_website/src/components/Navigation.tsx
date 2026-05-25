import { Menu, X } from 'lucide-react'
import { useState } from 'react'

const navLinks = [
  { name: 'Home', href: '#', active: true },
  { name: 'Features', href: '#features', active: false },
  { name: 'Download', href: '#download', active: false },
  { name: 'Contact', href: '#contact', active: false },
]

export default function Navigation() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <nav className="relative z-10 mx-auto flex max-w-7xl items-center justify-between px-8 py-6">
      {/* Logo */}
      <a href="#" className="font-display text-3xl tracking-tight text-foreground">
        Entangled<sup className="text-xs">®</sup>
      </a>

      {/* Desktop Nav Links */}
      <div className="hidden items-center gap-8 md:flex">
        {navLinks.map((link) => (
          <a
            key={link.name}
            href={link.href}
            className={`text-sm transition-colors ${
              link.active
                ? 'text-foreground'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {link.name}
          </a>
        ))}
      </div>

      {/* CTA Button */}
      <div className="hidden md:block">
        <a
          href="#download"
          className="liquid-glass inline-flex items-center rounded-full px-6 py-2.5 text-sm text-foreground transition-transform"
        >
          Get the App
        </a>
      </div>

      {/* Mobile Menu Button */}
      <button
        className="md:hidden text-foreground"
        onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        aria-label="Toggle menu"
      >
        {mobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
      </button>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="absolute left-0 right-0 top-full z-20 border-t border-border bg-background/95 backdrop-blur-lg md:hidden">
          <div className="flex flex-col gap-4 px-8 py-6">
            {navLinks.map((link) => (
              <a
                key={link.name}
                href={link.href}
                className={`text-sm ${
                  link.active ? 'text-foreground' : 'text-muted-foreground'
                }`}
                onClick={() => setMobileMenuOpen(false)}
              >
                {link.name}
              </a>
            ))}
            <a
              href="#download"
              className="liquid-glass mt-2 inline-flex items-center justify-center rounded-full px-6 py-2.5 text-sm text-foreground"
              onClick={() => setMobileMenuOpen(false)}
            >
              Get the App
            </a>
          </div>
        </div>
      )}
    </nav>
  )
}
