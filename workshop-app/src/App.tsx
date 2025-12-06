import { useEffect, useState } from 'react'
import { Navigation } from './components/Navigation'
import { MarkdownViewer } from './components/MarkdownViewer'
import { Terminal } from './components/Terminal'
import { Sheet, SheetContent, SheetTrigger } from './components/ui/sheet'
import { Button } from './components/ui/button'
import { List } from '@phosphor-icons/react'
import { useIsMobile } from './hooks/use-mobile'
import { useLocalStorage } from './hooks/use-local-storage'

// Red Hat Logo SVG Component
function RedHatLogo() {
  return (
    <div className="flex items-center gap-3">
      {/* Red Hat Fedora */}
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 180" className="h-10 w-auto flex-shrink-0">
        <path fill="#e00" d="M127 90.2c12.5 0 30.6-2.6 30.6-17.5a12.678 12.678 0 0 0-.3-3.4L149.8 37c-1.7-7.1-3.2-10.3-15.7-16.6-9.7-5-30.8-13.1-37.1-13.1-5.8 0-7.5 7.5-14.4 7.5-6.7 0-11.6-5.6-17.9-5.6-6 0-9.9 4.1-12.9 12.5 0 0-8.4 23.7-9.5 27.2a4.216 4.216 0 0 0-.3 1.9c0 9.2 36.3 39.4 85 39.4Zm32.5-11.4c1.7 8.2 1.7 9.1 1.7 10.1 0 14-15.7 21.8-36.4 21.8-46.8 0-87.7-27.4-87.7-45.5a17.535 17.535 0 0 1 1.5-7.3C21.8 58.8 0 61.8 0 81c0 31.5 74.6 70.3 133.7 70.3 45.3 0 56.7-20.5 56.7-36.6-.1-12.8-11-27.3-30.9-35.9Z"/>
        <path fill="#000" d="M159.5 78.8c1.7 8.2 1.7 9.1 1.7 10.1 0 14-15.7 21.8-36.4 21.8-46.8 0-87.7-27.4-87.7-45.5a17.535 17.535 0 0 1 1.5-7.3l3.7-9.1a4.877 4.877 0 0 0-.3 2c0 9.2 36.3 39.4 85 39.4 12.5 0 30.6-2.6 30.6-17.5a12.678 12.678 0 0 0-.3-3.4Z"/>
      </svg>
      {/* Red Hat Text */}
      <span className="text-white font-medium text-lg whitespace-nowrap" style={{ fontFamily: "'Red Hat Display', sans-serif" }}>
        Red Hat
      </span>
    </div>
  )
}

function App() {
  const [guides, setGuides] = useState<string[]>([])
  const [currentGuide, setCurrentGuide] = useLocalStorage<string>('current-guide', '')
  const [guideContent, setGuideContent] = useState<string>('')
  const [loading, setLoading] = useState(true)
  const [sheetOpen, setSheetOpen] = useState(false)
  const isMobile = useIsMobile()

  useEffect(() => {
    fetch('/api/guides')
      .then((res) => res.json())
      .then((data: string[]) => {
        setGuides(data)
        if (data.length > 0 && !currentGuide) {
          setCurrentGuide(data[0])
        }
        setLoading(false)
      })
      .catch((err) => {
        console.error('Error loading guides:', err)
        setLoading(false)
      })
  }, [])

  useEffect(() => {
    if (!currentGuide) return

    setLoading(true)
    fetch(`/api/guides/${currentGuide}`)
      .then((res) => res.text())
      .then((content) => {
        setGuideContent(content)
        setLoading(false)
      })
      .catch((err) => {
        console.error('Error loading guide content:', err)
        setGuideContent('# Error loading guide\n\nCould not load the content of this guide.')
        setLoading(false)
      })
  }, [currentGuide])

  const handleSelectGuide = (guide: string) => {
    setCurrentGuide(guide)
    setSheetOpen(false)
  }

  if (loading && guides.length === 0) {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-accent/30 border-t-accent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-sm text-muted-foreground font-medium">Loading workshop...</p>
        </div>
      </div>
    )
  }

  const navigationComponent = (
    <Navigation
      guides={guides}
      currentGuide={currentGuide || ''}
      onSelectGuide={handleSelectGuide}
      className="h-full"
    />
  )

  const displayTitle = currentGuide
    ? currentGuide.replace(/\.md$/, '').replace(/^\d+-/, '').replace(/-/g, ' ')
    : 'Select a guide'

  return (
    <div className="h-screen w-screen overflow-hidden bg-background flex flex-col">
      {/* Red Hat Style Header/Navbar */}
      <header className="h-14 bg-[var(--navbar-bg)] text-[var(--navbar-fg)] flex items-center px-4 flex-shrink-0">
        <div className="flex items-center gap-4">
          <RedHatLogo />
          <span className="text-[var(--navbar-fg)] font-normal text-base hidden sm:block">
            GitOps Virtualization Workshop
          </span>
        </div>
        {isMobile && (
          <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
            <SheetTrigger asChild>
              <Button size="sm" variant="ghost" className="ml-auto h-8 text-[var(--navbar-fg)] hover:bg-white/10">
                <List size={20} weight="bold" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-[280px] p-0">
              {navigationComponent}
            </SheetContent>
          </Sheet>
        )}
      </header>

      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar Navigation */}
        {!isMobile && (
          <aside className="w-60 flex-shrink-0">
            {navigationComponent}
          </aside>
        )}

        {/* Main Content Area */}
        <div className="flex-1 flex flex-col lg:flex-row overflow-hidden">
          {/* Guide Content Panel */}
          <main className="flex-1 flex flex-col overflow-hidden">
            {/* Toolbar */}
            <div className="h-10 px-4 bg-[var(--toolbar-bg)] border-b border-border flex items-center text-sm text-[var(--toolbar-fg)]">
              <nav className="flex items-center gap-2">
                <span>Workshop</span>
                <span>/</span>
                <span className="capitalize font-medium text-foreground">{displayTitle}</span>
              </nav>
            </div>
            
            {/* Document Content */}
            <div className="flex-1 overflow-y-auto">
              <article className="max-w-4xl mx-auto px-4 sm:px-6 py-6">
                {loading ? (
                  <div className="flex items-center justify-center py-16">
                    <div className="w-8 h-8 border-4 border-accent/30 border-t-accent rounded-full animate-spin" />
                  </div>
                ) : guideContent ? (
                  <>
                    <h1 className="text-2xl font-normal text-foreground mb-6 capitalize" style={{ fontFamily: "'Red Hat Display', sans-serif" }}>
                      {displayTitle}
                    </h1>
                    <MarkdownViewer content={guideContent} />
                  </>
                ) : (
                  <div className="text-center py-16">
                    <p className="text-sm text-muted-foreground">
                      Select a guide from the sidebar to get started
                    </p>
                  </div>
                )}
              </article>
            </div>
          </main>

          {/* Terminal Panel */}
          <div className="flex-1 flex flex-col overflow-hidden bg-[var(--terminal-bg)] border-l border-border">
            <Terminal className="h-full" />
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
