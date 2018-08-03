# frozen_string_literal: true

module Decidim
  # This class search for objects related to Metrics, and creates a new registry within
  # his own parameters
  class MetricManage
    def self.for(day_string)
      new(day_string)
    end

    def initialize(day_string)
      @day = day_string.present? ? Date.parse(day_string) : Time.zone.today - 1.day
      raise ArgumentError, "[ERROR] Malformed `day` argument. Format must be `YYYY-MM-DD` and in the past" if @day > Time.zone.today
      @day ||= Time.zone.today - 1.day
      @metric_name = ""
      clean
    end

    def clean
      @organization = nil
      @query = nil
      @cumulative = nil
      @quantity = nil
      @registry = nil
    end

    def valid?
      @day.present?
    end

    def with_context(organization)
      @organization = organization
      @query = @query.where(organization: organization)
    end

    def start_date
      @start_date ||= @day.beginning_of_day
    end

    def end_date
      @end_date ||= @day.end_of_day
    end

    def query
      raise "Not implemented"
    end

    def cumulative
      @cumulative ||= @query.count
    end

    def quantity
      @quantity ||= cumulative
    end

    def registry
      return if cumulative.zero?
      return @registry if @registry
      @registry = Decidim::Metric.find_or_initialize_by(day: @day.to_s, metric_type: @metric_name, organization: @organization)
      @registry.assign_attributes(cumulative: cumulative, quantity: quantity)
      @registry
    end

    def registry!
      registry.try(:save!)
    end
  end
end
