class Ezine::TestMember
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission
  include Ezine::MemberSearchable

  field :email, type: String
  field :email_type, type: String

  permit_params :email, :email_type

  belongs_to :node, class_name: "Cms::Node"

  validates :email, uniqueness: { scope: :node_id }, presence: true, email: true

  # Test member is always "enabled".
  scope :enabled, ->{ all }

  def email_type_options
    [
      [I18n.t('ezine.options.email_type.text'), 'text'],
      [I18n.t('ezine.options.email_type.html'), 'html'],
    ]
  end

  def test_member?
    true
  end
end
