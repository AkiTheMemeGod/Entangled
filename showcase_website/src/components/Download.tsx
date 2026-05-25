import { useState, useEffect, useCallback } from 'react'
import { motion } from 'framer-motion'
import { Download, ExternalLink, Smartphone, AlertCircle, Github, Shield, Star } from 'lucide-react'

interface ReleaseInfo {
  version: string
  releaseDate: string
  downloadUrl: string
  found: boolean
}

export default function DownloadSection() {
  const [releaseInfo, setReleaseInfo] = useState<ReleaseInfo>({
    version: '',
    releaseDate: '',
    downloadUrl: '',
    found: false,
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const fetchLatestRelease = useCallback(async () => {
    try {
      const response = await fetch(
        'https://api.github.com/repos/AkiTheMemeGod/Entangled/releases/latest'
      )

      if (!response.ok) {
        throw new Error('Failed to fetch release info')
      }

      const data = await response.json()

      const apkAsset = data.assets?.find((asset: { name: string }) =>
        asset.name.endsWith('.apk')
      )

      if (apkAsset) {
        setReleaseInfo({
          version: data.tag_name || 'v1.0.0',
          releaseDate: new Date(data.published_at).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          }),
          downloadUrl: apkAsset.browser_download_url,
          found: true,
        })
      } else {
        setReleaseInfo({
          version: data.tag_name || 'v1.0.0',
          releaseDate: new Date(data.published_at).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          }),
          downloadUrl: 'https://github.com/AkiTheMemeGod/Entangled/releases',
          found: false,
        })
      }
    } catch {
      setError(true)
      setReleaseInfo({
        version: '',
        releaseDate: '',
        downloadUrl: 'https://github.com/AkiTheMemeGod/Entangled/releases',
        found: false,
      })
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchLatestRelease()
  }, [fetchLatestRelease])

  return (
    <section id="download" className="relative z-10 bg-background py-32">
      <div className="mx-auto max-w-4xl px-8">
        <motion.div
          className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-secondary to-background p-12"
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          {/* Background decoration */}
          <div className="absolute -right-20 -top-20 h-40 w-40 rounded-full bg-foreground/5" />
          <div className="absolute -bottom-20 -left-20 h-40 w-40 rounded-full bg-foreground/5" />

          <div className="relative text-center">
            {/* Icon */}
            <motion.div
              className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-2xl border border-border bg-background"
              initial={{ scale: 0 }}
              whileInView={{ scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
            >
              <Smartphone className="h-8 w-8 text-foreground" />
            </motion.div>

            {/* Heading */}
            <h2
              className="mb-4 font-display text-4xl font-normal tracking-tight text-foreground sm:text-5xl"
              style={{ fontFamily: "'Instrument Serif', serif" }}
            >
              Ready to <em className="not-italic text-muted-foreground">start</em>?
            </h2>

            {/* Description */}
            <p className="mx-auto mb-6 max-w-lg text-lg text-muted-foreground">
              Join thousands of users who have already made the switch to private, 
              secure messaging. Download Entangled for Android today — completely free, 
              no ads, no tracking.
            </p>

            {/* Trust Badges */}
            <div className="mb-8 flex flex-wrap items-center justify-center gap-4 text-sm text-muted-foreground">
              <span className="flex items-center gap-1">
                <Shield className="h-4 w-4 text-green-400" />
                Verified Secure
              </span>
              <span className="flex items-center gap-1">
                <Star className="h-4 w-4 text-yellow-400" />
                4.8/5 Rating
              </span>
              <span className="flex items-center gap-1">
                <Download className="h-4 w-4" />
                1,000+ Downloads
              </span>
            </div>

            {/* Version info */}
            {loading ? (
              <div className="mb-8 flex items-center justify-center gap-2 text-muted-foreground">
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-foreground/20 border-t-foreground" />
                <span className="text-sm">Fetching latest release...</span>
              </div>
            ) : (
              <div className="mb-8">
                {releaseInfo.version && (
                  <p className="text-sm text-muted-foreground">
                    Latest version: <span className="text-foreground font-medium">{releaseInfo.version}</span>
                    {releaseInfo.releaseDate && (
                      <span> · Released {releaseInfo.releaseDate}</span>
                    )}
                  </p>
                )}
                {error && (
                  <p className="flex items-center justify-center gap-1 text-sm text-yellow-500/80">
                    <AlertCircle className="h-4 w-4" />
                    Could not fetch latest version
                  </p>
                )}
              </div>
            )}

            {/* Download button */}
            <motion.a
              href={releaseInfo.downloadUrl || 'https://github.com/AkiTheMemeGod/Entangled/releases'}
              target="_blank"
              rel="noopener noreferrer"
              className="liquid-glass group inline-flex items-center justify-center gap-3 rounded-full px-10 py-5 text-base text-foreground transition-transform"
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.98 }}
            >
              <motion.div
                animate={{ y: [0, -3, 0] }}
                transition={{ duration: 1.5, repeat: Infinity }}
              >
                <Download className="h-5 w-5" />
              </motion.div>
              <span>{releaseInfo.found ? 'Download APK' : 'View on GitHub'}</span>
              {!releaseInfo.found && <ExternalLink className="h-4 w-4" />}
            </motion.a>

            {/* GitHub link */}
            <a
              href="https://github.com/AkiTheMemeGod/Entangled"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-4 inline-flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              <Github className="h-4 w-4" />
              Star us on GitHub
            </a>

            {/* Requirements */}
            <p className="mt-6 flex items-center justify-center gap-2 text-xs text-muted-foreground">
              <Smartphone className="h-3 w-3" />
              Android 8.0+ required
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
