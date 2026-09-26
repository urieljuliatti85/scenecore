class CommunityTopicsController < ApplicationController
  before_action :set_band
  before_action :set_topic, only: [ :show, :destroy ]

  def index
    authorize CommunityTopic.new(band: @band)
    @topics = @band.community_topics.includes(:user, :community_replies).order(updated_at: :desc)
    @topic = CommunityTopic.new
    load_membership_levels(@topics.map(&:user_id))
  end

  def show
    authorize @topic
    @replies = @topic.community_replies.includes(:user)
    @reply = CommunityReply.new
    load_membership_levels([ @topic.user_id, *@replies.map(&:user_id) ])
  end

  def create
    @topic = @band.community_topics.new(topic_params.merge(user: current_user))
    authorize @topic

    if @topic.save
      redirect_to community_topic_path(@band.slug, @topic), notice: "Topic created."
    else
      @topics = @band.community_topics.includes(:user, :community_replies).order(updated_at: :desc)
      load_membership_levels(@topics.map(&:user_id))
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    authorize @topic
    log_platform_moderation(@topic)
    @topic.destroy!
    redirect_to public_band_community_path(@band.slug), notice: "Topic deleted."
  end

  private

  def set_band
    @band = Band.approved.find_by!(slug: params[:slug])
  end

  def set_topic
    @topic = @band.community_topics.find(params[:id])
  end

  def topic_params
    params.require(:community_topic).permit(:title, :body)
  end

  def load_membership_levels(user_ids)
    @membership_levels = @band.memberships.active.where(user_id: user_ids).pluck(:user_id, :level).to_h
  end

  def log_platform_moderation(subject)
    return unless current_user.platform_admin?
    return if subject.user_id == current_user.id
    return if @band.band_memberships.administrator.exists?(user_id: current_user.id)

    AdminActionLog.create!(actor: current_user, action: "moderate_delete_community_topic", subject: subject)
  end
end
