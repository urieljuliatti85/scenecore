import { Controller } from "@hotwired/stimulus"

// Debounced artist lookup against BandsController#search. Unlike the album
// search, picking a result only prefills the form's own fields: every one
// stays editable, and the band is created from whatever the user submits.
export default class extends Controller {
  static targets = ["query", "results", "name", "spotifyUrl", "imageUrl", "preview", "previewImage", "previewName"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

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
    this.renderResults(Array.isArray(results) ? results : [])
  }

  renderResults(results) {
    this.resultsTarget.innerHTML = ""

    results.forEach((artist) => {
      const item = document.createElement("li")
      item.className = "cursor-pointer rounded-lg px-4 py-2 hover:bg-neutral-800 flex items-center gap-3"

      if (artist.image_url) {
        const thumb = document.createElement("img")
        thumb.src = artist.image_url
        thumb.className = "w-8 h-8 rounded object-cover"
        item.appendChild(thumb)
      }

      const label = document.createElement("span")
      label.textContent = artist.name
      item.appendChild(label)

      item.addEventListener("click", () => this.select(artist))
      this.resultsTarget.appendChild(item)
    })
  }

  select(artist) {
    this.nameTarget.value = artist.name
    if (artist.spotify_url) this.spotifyUrlTarget.value = artist.spotify_url
    this.imageUrlTarget.value = artist.image_url || ""

    if (artist.image_url) {
      this.previewImageTarget.src = artist.image_url
      this.previewNameTarget.textContent = artist.name
      this.previewTarget.hidden = false
    } else {
      this.previewTarget.hidden = true
    }

    this.renderResults([])
    this.queryTarget.value = ""
  }

  // The user changed their mind about the Spotify photo; the text fields
  // they may have edited by hand are deliberately left alone.
  clearPhoto() {
    this.imageUrlTarget.value = ""
    this.previewTarget.hidden = true
  }
}
