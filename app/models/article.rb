class Article < ActiveRecord::Base

  include ElasticMapper

  has_many :studies, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => :owner_id
  has_many :article_authors, dependent: :destroy, autosave: true
  has_many :authors, -> {order 'article_authors.number ASC'}, :through => :article_authors
  has_many :model_updates, as: :changeable, dependent: :destroy
  has_many :bookmarks, class_name: "UserBookmark", as: :bookmarkable, dependent: :destroy

  validates_uniqueness_of :doi, unless: "doi.blank?"
  validates_presence_of :title

  serialize :authors_denormalized

  mapping :title, :doi, :index => :not_analyzed
  mapping :title, :abstract, :authors_for_index, :journal_title, :tags
  mapping :publication_date, :type => :date

  after_save :index
  after_destroy :delete_from_index
  before_save do
    self.doi = nil if self.doi.blank?
  end

  before_create do
    self.authors_denormalized = []
  end

  def add_author(first_name, middle_name, last_name)
    authors_denormalized.push(
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name
    )
    self
  end

  def authors_for_index
    indexable_authors = self.authors_denormalized
    if self.authors.count > 0
      indexable_authors = self.authors
    end
    indexable_authors.map do |a|
      "#{a[:first_name]} #{a[:middle_name]} #{a[:last_name]}"
    end.join(' ')
  end

  def as_json(opts={})
    super(opts).tap do |h|
      h['authors'] = self.authors if opts[:authors]
    end
  end

  def descendant_comments
    Comment.where(primary_commentable_id: self.id, primary_commentable_type: "Article")
  end
end
