# frozen_string_literal: true

module Wataridori
  class LinkReplacementRule
    RELATIVE_POST_PATH = %r{^/posts/(\d+)}

    def initialize(from, to, copy_results)
      @from = from
      @to = to
      @posts_map = copy_results.each_with_object({}) do |result, posts_map|
        posts_map[result.from.number] = result.to
      end
    end

    # URLを置換する必要があるかを返す
    def target?(link)
      return true if post_relative_link?(link)
      return true if query_url?(link)

      copied_post?(link)
    end

    def replaced(link)
      return link.gsub("https://#{from}.esa.io/", "https://#{to}.esa.io/") if query_url?(link)

      return esa_host_replaced(link) unless copied_post?(link)

      post_number = extract_post_number(link)
      return post_number_replaced(link, post_number) if post_number

      link
    end

    def post_relative_link?(link)
      # Linkが切れていた場合は無視する
      return false if link.is_a?(NilClass)
      link.start_with?('/posts/')
    end

    private

    attr_reader :from, :to, :posts_map

    def copied_post?(link)
      post_number = extract_post_number(link)
      post_number && posts_map[post_number]
    end

    def post_number_replaced(link, post_number)
      summary = posts_map[post_number]
      if post_relative_link?(link)
        link.gsub(RELATIVE_POST_PATH, "/posts/#{summary.number}")
      else
        summary.url
      end
    end

    def query_url?(link)
      # Linkが切れていた場合は無視する
      return false if link.is_a?(NilClass)
      link.start_with?("https://#{from}.esa.io/#") ||
        link.start_with?("https://#{from}.esa.io/posts?")
    end

    def esa_host_replaced(link)
      if post_relative_link?(link)
        "https://#{from}.esa.io#{link}"
      else
        link
      end
    end

    def extract_post_number(link)
      # Linkが切れていた場合は無視する
      return nil if link.is_a?(NilClass)
      path = link.gsub("https://#{from}.esa.io", '')
      m = path.match(RELATIVE_POST_PATH)
      m ? m[1].to_i : nil
    end
  end
end
