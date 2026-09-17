module ApplicationHelper
  # One link inside the header's centred nav pill, styled to match the
  # profile tab bar. The current page is marked by a tinted fill and border
  # rather than a solid block, which at this size reads as a highlight
  # instead of a button; the rest stay flat until hovered.
  def nav_pill_link(label, path, current:, icon: nil)
    classes = [ "flex items-center gap-2 rounded-full px-3.5 py-1.5 font-mono text-xs uppercase tracking-wider transition whitespace-nowrap" ]
    classes << if current
      "bg-yellow-400/10 text-yellow-300 border border-yellow-500/30"
    else
      "border border-transparent text-neutral-400 hover:text-white hover:bg-neutral-800"
    end

    link_to path, class: classes.join(" "), aria: { current: ("page" if current) } do
      safe_join([ (render("shared/nav_icon", icon: icon) if icon), tag.span(label) ].compact)
    end
  end

  def category_select_options
    Category.roots.includes(:subcategories).order(:name).flat_map do |root|
      [ [ root.name, root.id ] ] + root.subcategories.order(:name).map { |sub| [ "— #{sub.name}", sub.id ] }
    end
  end
end
