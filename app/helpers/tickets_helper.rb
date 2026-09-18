module TicketsHelper
  def ticket_qr_svg(ticket)
    svg = RQRCode::QRCode.new(ticket_check_in_url(ticket.public_token)).as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 5,
      standalone: true,
      use_path: true,
      viewbox: true
    )

    sanitize(
      svg,
      tags: %w[svg path rect],
      attributes: %w[xmlns width height viewBox fill d shape-rendering]
    )
  end
end
