module ApplicationHelper
  def category_select_options
    Category.roots.includes(:subcategories).order(:name).flat_map do |root|
      [ [ root.name, root.id ] ] + root.subcategories.order(:name).map { |sub| [ "— #{sub.name}", sub.id ] }
    end
  end
end
