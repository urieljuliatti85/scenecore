import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "selectedId", "selectedLabel", "name"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    this.clearSelection()

    const query = this.queryTarget.value.trim()
    if (query.length < 2) {
      this.renderResults([])
      return
    }

    this.timeout = setTimeout(() => this.performSearch(query), 300)
  }

  async performSearch(query) {
    const separator = this.urlValue.includes("?") ? "&" : "?"
    const response = await fetch(`${this.urlValue}${separator}q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })

    if (!response.ok) {
      this.renderError("Discogs search is unavailable right now.")
      return
    }

    const results = await response.json()
    this.renderResults(results)
  }

  renderResults(results) {
    this.resultsTarget.innerHTML = ""

    results.forEach((release) => {
      const item = document.createElement("li")
      item.className = "cursor-pointer rounded-lg px-4 py-3 hover:bg-neutral-800"

      const title = document.createElement("p")
      title.className = "text-sm font-medium text-white"
      title.textContent = `${release.title || "Untitled"} — ${release.artist || "Unknown artist"}`

      const details = document.createElement("p")
      details.className = "text-xs text-neutral-500 mt-1"
      details.textContent = [release.year, release.format, release.label, release.catalog_number, release.country].filter(Boolean).join(" · ")

      item.appendChild(title)
      item.appendChild(details)
      item.addEventListener("click", () => this.select(release))
      this.resultsTarget.appendChild(item)
    })
  }

  renderError(message) {
    this.resultsTarget.innerHTML = ""
    const item = document.createElement("li")
    item.className = "px-4 py-3 text-sm text-red-400"
    item.textContent = message
    this.resultsTarget.appendChild(item)
  }

  select(release) {
    this.selectedIdTarget.value = release.discogs_release_id
    this.nameTarget.value = release.title || ""
    this.selectedLabelTarget.textContent = `Selected: ${release.title || "Untitled"} — ${release.artist || "Unknown artist"} · Data provided by Discogs`
    this.selectedLabelTarget.hidden = false
    this.renderResults([])
    this.queryTarget.value = ""
  }

  clearSelection() {
    this.selectedIdTarget.value = ""
    this.selectedLabelTarget.hidden = true
  }
}
