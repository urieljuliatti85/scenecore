module Admin::SectionHelper
  # Each admin area gets its own accent so a glance at the sidebar, a heading
  # or a dashboard card says which part of the platform you are in. The
  # classes are spelled out in full rather than interpolated, because Tailwind
  # scans source text for literal class names and would drop anything built
  # at runtime.
  ADMIN_SECTION_ACCENTS = {
    dashboard: {
      text: "text-neutral-300",
      border: "border-neutral-700",
      dot: "bg-neutral-400",
      active: "bg-white text-black"
    },
    bands: {
      text: "text-emerald-400",
      border: "border-emerald-500/40",
      dot: "bg-emerald-400",
      active: "bg-emerald-400 text-black"
    },
    users: {
      text: "text-sky-400",
      border: "border-sky-500/40",
      dot: "bg-sky-400",
      active: "bg-sky-400 text-black"
    },
    memberships: {
      text: "text-violet-400",
      border: "border-violet-500/40",
      dot: "bg-violet-400",
      active: "bg-violet-400 text-black"
    },
    subscriptions: {
      text: "text-fuchsia-400",
      border: "border-fuchsia-500/40",
      dot: "bg-fuchsia-400",
      active: "bg-fuchsia-400 text-black"
    },
    moderation: {
      text: "text-rose-400",
      border: "border-rose-500/40",
      dot: "bg-rose-400",
      active: "bg-rose-400 text-black"
    },
    categories: {
      text: "text-teal-400",
      border: "border-teal-500/40",
      dot: "bg-teal-400",
      active: "bg-teal-400 text-black"
    },
    analytics: {
      text: "text-cyan-400",
      border: "border-cyan-500/40",
      dot: "bg-cyan-400",
      active: "bg-cyan-400 text-black"
    },
    reports: {
      text: "text-orange-400",
      border: "border-orange-500/40",
      dot: "bg-orange-400",
      active: "bg-orange-400 text-black"
    },
    audit_logs: {
      text: "text-amber-400",
      border: "border-amber-500/40",
      dot: "bg-amber-400",
      active: "bg-amber-400 text-black"
    },
    platform_settings: {
      text: "text-neutral-300",
      border: "border-neutral-700",
      dot: "bg-neutral-400",
      active: "bg-white text-black"
    }
  }.freeze

  DEFAULT_ADMIN_SECTION = :dashboard

  def admin_section_accent(section, variant)
    accents = ADMIN_SECTION_ACCENTS.fetch(section&.to_sym, ADMIN_SECTION_ACCENTS[DEFAULT_ADMIN_SECTION])
    accents.fetch(variant.to_sym)
  end
end
