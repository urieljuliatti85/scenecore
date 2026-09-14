import { Controller } from "@hotwired/stimulus"

// Debounced search-as-you-type against AlbumsController#search. Selecting a
// result fills the hidden spotify_album_id field the form actually submits
// — the query text itself is never sent to the server on submit.
export default class extends Controller {
  static targets = ["query", "results", "selectedId", "selectedLabel", "submit"]
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
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })

    if (!response.ok) {
      this.renderResults([])
      return
    }

    const results = await response.json()
    this.renderResults(results)
  }

  renderResults(results) {
    this.resultsTarget.innerHTML = ""

    results.forEach((album) => {
      const item = document.createElement("li")
      item.className = "cursor-pointer rounded-lg px-4 py-2 hover:bg-neutral-800 flex items-center gap-3"
      item.textContent = `${album.name} — ${album.artist || "Unknown artist"} (${album.release_year || "?"})`
      item.addEventListener("click", () => this.select(album))
      this.resultsTarget.appendChild(item)
    })
  }

  select(album) {
    this.selectedIdTarget.value = album.spotify_id
    this.selectedLabelTarget.textContent = `Selected: ${album.name} — ${album.artist || "Unknown artist"}`
    this.selectedLabelTarget.hidden = false
    this.renderResults([])
    this.queryTarget.value = ""
    this.submitTarget.disabled = false
  }

  clearSelection() {
    this.selectedIdTarget.value = ""
    this.selectedLabelTarget.hidden = true
    this.submitTarget.disabled = true
  }
}
