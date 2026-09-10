# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email_address) { "member#{_1}@example.com" }
    sequence(:name) { "Member #{_1}" }
    password { "correct-horse-battery" }
    confirmed_at { Time.current }
  end

  factory :community do
    sequence(:slug) { "community-#{_1}" }
    sequence(:name) { "Community #{_1}" }
    privacy { "public" }
    published_at { Time.current }
  end

  factory :membership do
    user
    community
    role { "member" }
    status { "active" }
    joined_at { 30.days.ago }
  end

  factory :category do
    community
    sequence(:name) { "Category #{_1}" }
    sequence(:slug) { "category-#{_1}" }
  end

  factory :post do
    community
    category
    user
    sequence(:title) { "Post #{_1}" }
    body { RichText::Document.from_plain_text("Some body text.") }
    last_activity_at { Time.current }
  end

  factory :plan do
    community
    sequence(:name) { "Plan #{_1}" }
    sequence(:slug) { "plan-#{_1}" }
    amount_cents { 8_900 }
    currency { "GBP" }
  end

  factory :course do
    community
    sequence(:title) { "Course #{_1}" }
    sequence(:slug) { "course-#{_1}" }
    published_at { Time.current }
  end

  factory :course_module do
    community
    course
    title { "Module" }
  end

  factory :lesson do
    community
    course_module
    sequence(:title) { "Lesson #{_1}" }
    sequence(:slug) { "lesson-#{_1}" }
    published_at { Time.current }
  end
end
