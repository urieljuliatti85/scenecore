class AddMembershipPresalesToTicketBatches < ActiveRecord::Migration[8.1]
  def change
    change_table :ticket_batches, bulk: true do |t|
      t.datetime :fan_sales_start_at
      t.datetime :supporter_sales_start_at
      t.datetime :core_member_sales_start_at
    end
  end
end
