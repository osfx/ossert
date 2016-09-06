module Ossert
  class ProjectDecorator
    attr_reader :project

    def initialize(project)
      @project = project
      @reference = Ossert::Classifiers::Growing.current.reference_values_per_class
    end

    def with_reference(text, value, metric, type)
      value = value.to_f * 4 if type.to_s =~ /quarter/
      reference = @reference[type][metric].inject('NaN') do |acc, (ref, ref_values)|
        ref_values[:range].cover?(value) ? ref : acc
      end
      "#{text} (#{reference.gsub(/Class/, '')})"
    rescue => e
      puts "NO DATA FOR METRIC: '#{metric}'"
      raise e
    end

    def percent(value)
      "#{value}%"
    end

    def date(value)
      Time.at(value).strftime('%d-%m-%Y')
    end

    def years(value)
      "#{value.to_i / 365}+ years"
    end

    def downloads(value)
      value.to_s.gsub(/\d(?=(...)+$)/, '\0,')
    end

    def decorate_metric(metric, value, type)
      case metric.to_s
      when /(percent|divergence)/
        with_reference(
          percent(value),
          value,
          metric,
          type
        )
      when /(date|changed)/
        with_reference(
          date(value),
          value,
          metric,
          type
        )
      when /period/
        with_reference(
          years(value),
          value,
          metric,
          type
        )
      when /count/
        with_reference(
          value.to_i,
          value,
          metric,
          type
        )
      when /downloads/
        with_reference(
          downloads(value),
          value,
          metric,
          type
        )
      else
        with_reference(
          value,
          value,
          metric,
          type
        )
      end
    end

    def agility_total
      @project.agility.total.metrics_to_hash.each_with_object({}) do |(metric, value), res|
        metric_name = metric.to_s.gsub(/(_percent|_int|_count)/, '')
        res[metric_name] = decorate_metric metric, value, :agility_total
      end
    end

    def agility_quarter(quarter)
      quarter = Time.at(quarter).to_date.to_time(:utc).beginning_of_quarter
      @project.agility.quarters[quarter].metrics_to_hash.each_with_object({}) do |(metric, value), res|
        metric_name = metric.to_s.gsub(/(_percent|_int|_count)/, '')
        res[metric_name] = decorate_metric metric, value, :agility_quarter
      end
    end

    def community_total
      @project.community.total.metrics_to_hash.each_with_object({}) do |(metric, value), res|
        metric_name = metric.to_s.gsub(/(_percent|_int|_count)/, '')
        res[metric_name] = decorate_metric metric, value, :community_total
      end
    end

    def community_quarter(quarter)
      quarter = Time.at(quarter).to_date.to_time(:utc).beginning_of_quarter
      @project.community.quarters[quarter].metrics_to_hash.each_with_object({}) do |(metric, value), res|
        metric_name = metric.to_s.gsub(/(_percent|_int|_count)/, '')
        res[metric_name] = decorate_metric metric, value, :community_quarter
      end
    end
  end
end