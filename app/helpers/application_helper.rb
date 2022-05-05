module ApplicationHelper
  def bootstrap_class_for flash_type
    case flash_type
      when :success
        "alert-success"
      when :error
        "alert-danger"
      when :alert
        "alert-warning"
      when :notice
        "alert-info"
      else
        flash_type.to_s
    end
  end

  def button_class_for btn_type
    case btn_type
      when :complete
        { i_class: 'glyphicon glyphicon-ok', text: "Complete" }
      when :cancel
        { i_class: 'glyphicon glyphicon-remove', text: "Cancel" }
      when :re_schedule
        { i_class: 'glyphicon glyphicon-calendar', text: "Re-schedule" }
      when :extend
        { i_class: 'fa fa-plus', text: "Extend" }
      when :resume
        { i_class: 'fa fa-retweet', text: "Resume" }
      else
        raise NameError
    end
  end
=begin
  def dropbox_menu_for_select(tabs, selected=nil)
    content_tag :ul, :class => "dropdown-menu" do
      tabs.each do |title, url|
        content_tag :li, :class => (selected==title ? "active" : "") do
          link_to title, url
        end
      end
    end
  end
=end

  def local_datetime_format(time_to_parse)
    time_to_parse.in_time_zone("Beijing").strftime("%Y-%m-%d %H:%M:%S")
  end


  def display_boolean(bool)

  end

  def to_currency(value, delimiter=',', decimal=2, show=false)
    dollar, cent = value.to_s.split('.')

    dollar = (dollar).gsub(
        /(\d)(?=(?:\d{3})+(?:$|\.))/,
        "\\1#{delimiter}"
    )

    if decimal.nil?
      cent = show ? '0' : ''
    elsif cent.nil?
      cent = show ? '0' * decimal : ''
    else
      cent = cent[0, decimal] if cent.length > decimal
      while cent[-1, 1] == '0' do cent[-1, 1] = "" end
      cent = cent + '0' * (decimal - cent.length) if show && cent.length < decimal
    end
    cent = cent + '0' * (decimal - cent.length) if show && cent.length < decimal
    cent = '.' + cent unless cent.empty?

    return dollar + cent
  end

  def cents_to_dollars(value)
    value = value.to_f
    value = value / 100
    value
  end

  # e.g.
  #
  # breadcrumbs([ property_tag(@selected_property_id), t("tree_view.slot"), t("general.log") ], 'fa fa-lg fa-table')
  #
  def breadcrumbs(titles, icon_class, options={})
    dom_id = options[:id] || "breadcrumbs"
    klass = options[:class] || "col-xs-12 col-sm-12 col-md-12 col-lg-12"

    content_tag :div, :class => "row" do
      content_tag :div, :id => dom_id, :class => klass do
        content_tag :h2, :class => "page-title txt-color-blueDark" do
          concat content_tag(:i, nil, :class => icon_class)

          titles.each_with_index.map do |title, index|
            label = " #{title} "
            separator = '&gt;'.html_safe

            if (index + 1) == titles.length  && index != 0
              span = content_tag :span do
                concat separator
                concat label
              end
              concat span
            elsif index != 0
              concat separator
              concat label
            else
              concat label
            end
          end
        end
      end
    end
  end

  #
  # table_tabs("Current", ["Current", test_players_path, policy(:test_player).index?]
  #                        ["Deprecated", list_deprecated_test_players_path, policy(:test_player).list_deprecated?])
  #
  def table_tabs(selected, *tabs)
    content_tag :ul, :class => "nav nav-tabs bordered" do
      tabs.each do |tab_info|
        title = tab_info[0]
        path = tab_info[1]
        visible = tab_info[2]

        if visible
          li_div = content_tag(:li, nil, :class => selected == title ? "active" : "" ) do
            concat link_to(title, path, "data-target" => "#", :remote => true, "data-toggle" => "tab")
          end

          concat li_div
        end
      end
    end
  end

  def popover(name, title, content, rel, placement)
    link_to(name, "javascript:void(0);", "rel" => rel, "data-placement" => placement, "data-content" => content, "data-original-title" => title)
  end

  def property_tag(property_id)
    "#{t("maintenance.property")} #{property_id}"
  end

  def display_text(text, empty_indicator='-')
    text.nil? ? '-' : text.titleize
  end

  def display_from_to(hash)
    return '' if hash.blank?
    text = ''
    hash.each_with_index do |(key, value), index|
      value = '******' if key.include?('password') && value.present?
      text += "#{key}:#{value}; "
      text += "<br/>" if index % 2 != 0
    end
    text
  end

  def gen_select_options(targets)
    selection = targets.map { |target| [ target.name.titleize, target.id.to_s ] }
    selection.unshift([ t("general.all"), "all" ])
    options_for_select selection
  end
end
