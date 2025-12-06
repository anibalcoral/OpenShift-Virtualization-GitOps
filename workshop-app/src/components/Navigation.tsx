import { cn } from '@/lib/utils'
import { Book, CaretRight } from '@phosphor-icons/react'

interface NavigationProps {
  guides: string[]
  currentGuide: string
  onSelectGuide: (guide: string) => void
  className?: string
}

export function Navigation({ guides, currentGuide, onSelectGuide, className }: NavigationProps) {
  return (
    <div className={cn('flex flex-col h-full bg-[var(--sidebar-bg)] border-r border-border/50', className)}>
      <div className="px-4 py-4 border-b border-border/30">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded bg-accent flex items-center justify-center">
            <Book size={18} weight="bold" className="text-accent-foreground" />
          </div>
          <div>
            <p className="text-xs text-[var(--sidebar-fg)]/70">GitOps Virtualization Workshop</p>
          </div>
        </div>
      </div>
      <div className="flex-1 overflow-y-auto">
        <div className="p-2">{guides.length === 0 ? (
            <div className="px-3 py-8 text-sm text-[var(--sidebar-fg)]/60 text-center">
              No guides available
            </div>
          ) : (
            <div className="space-y-0.5">
              {guides.map((guide, index) => {
                const isActive = guide === currentGuide
                const displayName = guide.replace(/\.md$/, '').replace(/^\d+-/, '').replace(/-/g, ' ')
                
                return (
                  <button
                    key={guide}
                    onClick={() => onSelectGuide(guide)}
                    className={cn(
                      'w-full text-left px-3 py-2.5 rounded-sm text-sm transition-all group relative',
                      'hover:bg-[var(--sidebar-hover)]',
                      isActive 
                        ? 'bg-accent text-accent-foreground font-medium shadow-sm' 
                        : 'text-[var(--sidebar-fg)]'
                    )}
                  >
                    <div className="flex items-center gap-3">
                      <span className={cn(
                        "text-xs font-mono min-w-[2rem] px-1.5 py-0.5 rounded-sm flex-shrink-0",
                        isActive 
                          ? "bg-accent-foreground/20 text-accent-foreground" 
                          : "bg-[var(--sidebar-fg)]/10 text-[var(--sidebar-fg)]/60"
                      )}>
                        {String(index + 1).padStart(2, '0')}
                      </span>
                      <span className="capitalize flex-1 break-words leading-snug">{displayName}</span>
                      {isActive && (
                        <CaretRight size={14} weight="bold" className="text-accent-foreground flex-shrink-0" />
                      )}
                    </div>
                  </button>
                )
              })}
            </div>
          )}
        </div>
      </div>
      <div className="px-4 py-3 border-t border-border/30">
        <div className="flex items-center gap-2 text-xs text-[var(--sidebar-fg)]/50">
          <div className="w-1.5 h-1.5 rounded-full bg-success" />
          <span>Red Hat One 2026</span>
        </div>
      </div>
    </div>
  )
}
