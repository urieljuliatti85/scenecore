class CommentsController < ApplicationController
  before_action :set_post

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create
    @comment = @post.comments.new(comment_params.merge(user: current_user))
    authorize @comment

    if @comment.save
      redirect_to public_band_path(params[:slug], anchor: "post-#{@post.id}"), notice: "Comment posted."
    else
      redirect_to public_band_path(params[:slug], anchor: "post-#{@post.id}"), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    authorize @comment

    log_platform_moderation
    @comment.destroy
    redirect_to public_band_path(params[:slug], anchor: "post-#{@post.id}"), notice: "Comment deleted."
  end

  private

  def set_post
    @band = Band.approved.find_by!(slug: params[:slug])
    @post = @band.posts.published.find(params[:post_id])
  end

  # Platform moderation must be auditable (docs/community.md §11) — the
  # comment's own author or the post's band deleting it is ordinary
  # moderation of their own content, not a platform intervention.
  def log_platform_moderation
    return unless current_user.platform_admin?
    return if @comment.user_id == current_user.id
    return if @band.band_memberships.exists?(user_id: current_user.id)

    AdminActionLog.create!(actor: current_user, action: "moderate_delete_comment", subject: @comment)
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
