class ReplicationsController < ApplicationController
  #before_action :authenticate_user!
  #before_filter :authenticate!

  before_filter :authenticate_user!
  before_filter :check_can_curate, :only => [:create, :update, :destroy]

  def index
    [:study_id].each do |k|
      raise "#{k} must be provided" if params[k].nil?
    end

    study_id = params[:study_id] ? params[:study_id].to_i : -1

    if params[:article_id]
      article_id = params[:article_id] ? params[:article_id].to_i : -1

      render json: Article.find(article_id)
        .studies.find(study_id)
        .replications.as_json(authors: true, replications: true, year: true, comments: true)
    else
      render json: Study.find(study_id)
        .replications.as_json(authors: true, replications: true, year: true, comments: true)
    end
  rescue ActiveRecord::RecordNotFound => ex
    render json: {error: ex.to_s}, status: 404
  rescue StandardError => ex
    Raven.capture_exception(ex)
    render json: {error: "unknown error"}, status: 500
  end

  def show
    [:study_id, :id].each do |k|
      raise "#{k} must be provided" if params[k].nil?
    end

    study_id = params[:study_id] ? params[:study_id].to_i : -1
    id = params[:id] ? params[:id].to_i : -1

    if params[:article_id]
      article_id = params[:article_id] ? params[:article_id].to_i : -1

      render json: Article.find(article_id)
        .studies.find(study_id)
        .replications.find(id)
        .as_json(authors: true, replications: true, year: true, comments: true)
    else
      render json: Study.find(study_id)
        .replications.find(id)
        .as_json(authors: true, replications: true, year: true, comments: true)
    end
  rescue ActiveRecord::RecordNotFound => ex
    render json: {error: ex.to_s}, status: 404
  rescue StandardError => ex
    Raven.capture_exception(ex)
    render json: {error: "unknown error"}, status: 500
  end

  def create
    [:article_id, :study_id, :replicating_study_id].each do |k|
      raise "#{k} must be provided" if params[k].nil?
    end

    article_id = params[:article_id].to_i
    study_id = params[:study_id].to_i
    replicating_study_id = params[:replicating_study_id].to_i
    closeness = params[:closeness].to_i

    study = Article.find(article_id).studies.find(study_id)
    replicating_study = Study.find(replicating_study_id)

    replication = study.add_replication(
      replicating_study,
      closeness,
      current_user
    )

    Article.find(article_id).update(updater: current_user) if current_user

    render json: replication.as_json(authors: true, replications: true), status: 201
  rescue ActiveRecord::RecordInvalid => ex
    render_error(ex)
  rescue ActiveRecord::RecordNotFound => ex
    render json: {error: ex.to_s}, status: 404
  rescue StandardError => ex
    Raven.capture_exception(ex)
    render json: {error: "unknown error"}, status: 500
  end

  def update
    [:study_id, :id].each do |k|
      raise "#{k} must be provided" if params[k].nil?
    end

    article_id = params[:article_id] ? params[:article_id].to_i : -1
    study_id = params[:study_id] ? params[:study_id].to_i : -1
    id = params[:id] ? params[:id].to_i : -1

    closeness = params[:closeness].to_i

    if article_id != -1
      replication = Article.find(article_id)
        .studies.find(study_id)
        .replications.find(id)
      Article.find(article_id).update(updater: current_user) if current_user
    else
      replication = Study.find(study_id)
        .replications.find(id)
    end


    replication.update!({
      closeness: closeness
    })

    render json: replication.as_json(authors: true, replications: true)
  rescue ActiveRecord::RecordInvalid => ex
    render_error(ex)
  rescue ActiveRecord::RecordNotFound => ex
    render json: {error: ex.to_s}, status: 404
  rescue StandardError => ex
    Raven.capture_exception(ex)
    render json: {error: "unknown error"}, status: 500
  end

  def destroy
    [:id].each do |k|
      raise "#{k} must be provided" if params[k].nil?
    end

    replication = Replication.find(params[:id].to_i)

    # currently replications created with no owner
    # can be deleted by anyone.
    if not replication.owner or replication.owner == current_user or current_user.admin
      replication.destroy!
      render json: {success: true, data: replication.as_json(replications: true)}, status: 204
    else
      render json: {error: 'not allowed'}, status: 401
    end

  rescue ActiveRecord::RecordNotFound => ex
    render json: {error: ex.to_s}, status: 404
  rescue StandardError => ex
    Raven.capture_exception(ex)
    render json: {error: "unknown error"}, status: 500
  end
end
