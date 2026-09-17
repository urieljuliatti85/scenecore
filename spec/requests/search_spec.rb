require "rails_helper"

RSpec.describe "Search", type: :request do
  describe "GET /search" do
    it "is accessible without authentication" do
      get search_path

      expect(response).to have_http_status(:ok)
    end

    it "defaults to band search when no type is given" do
      band = create(:band, :approved, name: "Farscape")

      get search_path(q: "Farscape")

      expect(response.body).to include("Farscape")
    end

    context "when searching for bands" do
      it "finds an approved band by a partial, case-insensitive name match" do
        create(:band, :approved, name: "Farscape")

        get search_path(type: "band", q: "farsc")

        expect(response.body).to include("Farscape")
      end

      it "does not find a pending band" do
        create(:band, name: "Secretbandname")

        get search_path(type: "band", q: "Secretband")

        expect(response.body).not_to include("Secretbandname")
      end

      it "does not find a suspended band" do
        create(:band, :suspended, name: "Secretbandname")

        get search_path(type: "band", q: "Secretband")

        expect(response.body).not_to include("Secretbandname")
      end

      it "returns no results for a query that matches nothing" do
        create(:band, :approved, name: "Farscape")

        get search_path(type: "band", q: "nonexistent")

        expect(response.body).to include("No results found")
      end
    end

    context "when searching for albums" do
      it "finds a published album from an approved band" do
        band = create(:band, :approved)
        create(:album, :published, band: band, title: "Discovery")

        get search_path(type: "album", q: "discov")

        expect(response.body).to include("Discovery")
      end

      it "does not find a draft album" do
        band = create(:band, :approved)
        create(:album, band: band, title: "Secretalbumtitle")

        get search_path(type: "album", q: "Secretalbum")

        expect(response.body).not_to include("Secretalbumtitle")
      end

      it "does not find a published album belonging to a non-approved band" do
        band = create(:band)
        create(:album, :published, band: band, title: "Secretalbumtitle")

        get search_path(type: "album", q: "Secretalbum")

        expect(response.body).not_to include("Secretalbumtitle")
      end
    end

    it "does not raise when the query contains SQL LIKE wildcards" do
      create(:band, :approved, name: "100% Wolf")

      get search_path(type: "band", q: "100%")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("100% Wolf")
    end

    it "shows a prompt instead of results when there is no query" do
      get search_path(type: "band")

      expect(response.body).to include("Search for a band or an album")
    end

    # The header has no search field, so this page must carry its own or
    # there is nowhere to type.
    it "renders a search form on the page itself" do
      get search_path

      expect(response.body).to include("name=\"q\"")
      expect(response.body).to include("name=\"type\"")
    end

    it "keeps the current query and type in the form after searching" do
      create(:band, :approved, name: "Farscape")

      get search_path(type: "band", q: "Farscape")

      expect(response.body).to include("value=\"Farscape\"")
    end
  end
end
