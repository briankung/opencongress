# == Schema Information
#
# Table name: bills
#
#  id                     :integer          not null, primary key
#  session                :integer
#  bill_type              :string(7)
#  number                 :integer
#  introduced             :integer
#  sponsor_id             :integer
#  lastaction             :integer
#  rolls                  :string(255)
#  last_vote_date         :integer
#  last_vote_where        :string(255)
#  last_vote_roll         :integer
#  last_speech            :integer
#  pl                     :string(255)
#  topresident_date       :integer
#  topresident_datetime   :date
#  summary                :text
#  plain_language_summary :text
#  hot_bill_category_id   :integer
#  updated                :datetime
#  page_views_count       :integer
#  is_frontpage_hot       :boolean
#  news_article_count     :integer          default(0)
#  blog_article_count     :integer          default(0)
#  caption                :text
#  key_vote_category_id   :integer
#  is_major               :boolean
#  top_subject_id         :integer
#  short_title            :text
#  popular_title          :text
#  official_title         :text
#  manual_title           :text
#

require 'spec_helper'

describe Bill do
  describe "related_articles" do
    # FIXME: These tests are on the wrong model. finds related articles
    # Should test the model method, not Article's acts_as_taggable finders.
    # Leaving because they're useful currently, but this should be revisited.
    let(:bill) { Bill.new }

    before(:each) do
      @article = Article.create!
      @article.tag_list = 'foo,bar,baz'
      @article.save!
    end

    it "finds related articles" do
      allow(bill).to receive_messages(subject_terms: "foo")
      expect(bill.related_articles).to eq [@article]
    end

    it "can match on multiple tags" do
      allow(bill).to receive_messages(subject_terms: "foo,bar")
      expect(bill.related_articles).to eq [@article]
    end

    it "can match any of a bill's subjects" do
      allow(bill).to receive_messages(subject_terms: "foo,bar,other,another,yet another")
      expect(bill.related_articles).to eq [@article]
    end

    it "won't match if there are no matching tags" do
      allow(bill).to receive_messages(subject_terms: "other")
      expect(bill.related_articles).to be_empty
    end

    it "won't match if there are no tags" do
      allow(bill).to receive_messages(subject_terms: "")
      expect(bill.related_articles).to be_empty
    end
  end

  describe '#find_all_by_most_user_votes_for_range' do

    describe 'sets order specified by option hash or 20 by default' do
      before(:each) do
        @iteration_count = 10
        @iteration_count.times do |first_iteration|
          bill = FactoryGirl.create(:bill, id: first_iteration + 1)
          first_iteration.times do |second_iteration|
            bill.bill_votes.create(support: 0)
          end
        end
      end

      it 'has no specified order' do
        response = Bill.find_all_by_most_user_votes_for_range(nil, {})
        expect(response.first.id).to  eq @iteration_count
      end

      it 'has current_support_pb assigned as order' do
        response = Bill.find_all_by_most_user_votes_for_range(nil, {order: "current_support_pb desc"})
         expect(response.first.id).to  eq @iteration_count
      end

      it 'has support_count assigned as order' do
        @bill = Bill.find(10)
        @bill.bill_votes.each do |bill_vote|
          bill_vote.support = 1
          bill_vote.save
        end

        response = Bill.find_all_by_most_user_votes_for_range(nil, {order: "support_count_1 desc"})
        expect(response.first.id).to  eq @iteration_count

        response = Bill.find_all_by_most_user_votes_for_range(nil, {order: "support_count_1 asc"})
        expect(response.last.id).to  eq @iteration_count
      end
    end

    it 'defauls the range to 30 days if not specified' do
      @bill = FactoryGirl.create(:bill)
      @bill_vote = @bill.bill_votes.create(user:User.find(13))

      response  = Bill.find_all_by_most_user_votes_for_range(nil, {})
      expect(response).to include(@bill)
    end
  end
end

