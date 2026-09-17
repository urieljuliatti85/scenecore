module ApplicationHelper
  # One link inside the header's centred nav pill. The current page gets a
  # filled capsule; the rest stay flat until hovered.
  def nav_pill_link(label, path, current:)
    classes = [ "rounded-full px-4 py-1.5 text-sm font-medium transition whitespace-nowrap" ]
    classes << (current ? "bg-yellow-400 text-black" : "text-neutral-300 hover:text-white hover:bg-neutral-800")

    link_to label, path, class: classes.join(" ")
  end

  def category_select_options
    Category.roots.includes(:subcategories).order(:name).flat_map do |root|
      [ [ root.name, root.id ] ] + root.subcategories.order(:name).map { |sub| [ "— #{sub.name}", sub.id ] }
    end
  end
end
