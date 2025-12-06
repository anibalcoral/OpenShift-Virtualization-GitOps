import { useEffect, useState } from 'react'
import { Navigation } from './components/Navigation'
import { MarkdownViewer } from './components/MarkdownViewer'
import { Terminal } from './components/Terminal'
import { Sheet, SheetContent, SheetTrigger } from './components/ui/sheet'
import { Button } from './components/ui/button'
import { List, FileText, Cube } from '@phosphor-icons/react'
import { useIsMobile } from './hooks/use-mobile'
import { useLocalStorage } from './hooks/use-local-storage'

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

  return (
    <div className="h-screen w-screen overflow-hidden bg-background flex flex-col">
      {isMobile && (
        <div className="flex items-center justify-between px-4 py-3 bg-primary text-primary-foreground border-b border-border/50 shadow-sm">
          <div className="flex items-center gap-2">
            <Cube size={20} weight="bold" />
            <h1 className="text-base font-semibold">GitOps Workshop</h1>
          </div>
          <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
            <SheetTrigger asChild>
              <Button size="sm" variant="ghost" className="h-8 text-primary-foreground hover:bg-primary-foreground/20">
                <List size={20} weight="bold" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-[280px] p-0">
              {navigationComponent}
            </SheetContent>
          </Sheet>
        </div>
      )}

      <div className="flex-1 flex overflow-hidden">
        {!isMobile && (
          <div className="w-64 flex-shrink-0">
            {navigationComponent}
          </div>
        )}

        <div className="flex-1 flex flex-col lg:flex-row overflow-hidden">
          <div className="flex-1 flex flex-col overflow-hidden border-r border-border">
            <div className="px-6 py-4 bg-card border-b border-border">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-sm bg-accent/10 flex items-center justify-center">
                  <FileText size={18} weight="bold" className="text-accent" />
                </div>
                <div>
                  <h1 className="text-xl font-bold text-foreground capitalize">
                    {currentGuide
                      ? currentGuide.replace(/\.md$/, '').replace(/^\d+-/, '').replace(/-/g, ' ')
                      : 'Select a guide'}
                  </h1>
                  {currentGuide && (
                    <p className="text-xs text-muted-foreground mt-0.5">
                      Follow the instructions and execute commands in the terminal
                    </p>
                  )}
                </div>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto">
              <div className="px-6 py-6">
                {loading ? (
                  <div className="flex items-center justify-center py-16">
                    <div className="w-8 h-8 border-4 border-accent/30 border-t-accent rounded-full animate-spin" />
                  </div>
                ) : guideContent ? (
                  <MarkdownViewer content={guideContent} />
                ) : (
                  <div className="text-center py-16">
                    <FileText size={48} weight="thin" className="text-muted-foreground/40 mx-auto mb-4" />
                    <p className="text-sm text-muted-foreground">
                      Select a guide from the sidebar to get started
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="flex-1 flex flex-col overflow-hidden bg-muted/30">
            <Terminal className="h-full p-4" />
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
