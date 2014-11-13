# == Schema Information
#
# Table name: gossip
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  title      :string(255)
#  email      :string(255)
#  link       :string(255)
#  tip        :text
#  frontpage  :boolean          default(FALSE)
#  approved   :boolean          default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#

class Gossip < OpenCongressModel
  validates_presence_of :email, :name, :tip
  self.table_name = 'gossip'

  def self.latest(number = 10)
    self.where(approved: true ).order('created_at desc').limit(number)
  end

  def Gossip.frontpage(number = 4)
    Gossip.find :all, :limit => number, :order => "created_at desc", :conditions => 'frontpage = true'
  end

  def Gossip.today
    Gossip.find :all, :order => "created_at desc", :conditions => ['published = true && created_at > ?', Time.now.beginning_of_day] 
  end

  def Gossip.for_admin
    Gossip.find :all, :order => "frontpage desc, approved desc, updated_at, created_at"
  end

  def tip_html
    return RedCloth.new(tip).to_html
  end

  def formatted_date
    created_at.strftime "%b %e, %y"
  end

end
