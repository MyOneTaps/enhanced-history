class BH.Views.DayResultsView extends Backbone.View
  @include BH.Modules.I18n

  template: BH.Templates['day_results']

  events:
    'click .delete_visit': 'deleteVisitClicked'
    'click .delete_grouped_visit': 'deleteGroupedVisitClicked'
    'click .delete_interval': 'deleteIntervalClicked'
    'click .show_visits': 'toggleGroupedVisitsClicked'
    'click .hide_visits': 'toggleGroupedVisitsClicked'
    'click .visit > a': 'visitClicked'

  initialize: ->
    @chromeAPI = chrome

  render: ->
    properties = _.extend @getI18nValues(), @model.toTemplate()
    html = Mustache.to_html @template, properties
    @$el.html html

    @

  insertTags: ->
    persistence = new BH.Persistence.Tag localStore: localStore
    persistence.cached (operations) ->
      $('.site').each ->
        $el = $(this)
        tags = operations.siteTags $el.attr('href')
        activeTagsView = new BH.Views.ActiveTagsView
          model: new BH.Models.Site(tags: tags)
          editable: false
        $el.find('.active_tags').html activeTagsView.render().el

        $('.sites').each (i, siteEl) =>
          $el = $(siteEl)
          tagsBySite = []
          $el.parents('.visit').find('.site').each ->
            siteTags = []
            $(this).find('.tag').each ->
              siteTags.push $(this).data('tag')
            tagsBySite.push siteTags

          sharedTags = _.intersection.apply(@, tagsBySite)

          activeTagsView = new BH.Views.ActiveTagsView
            model: new BH.Models.Site(tags: sharedTags)
            editable: false
          $el.find('.active_tags').eq(0).html activeTagsView.render().el

  attachDragging: ->
    dragAndTagView = new BH.Views.DragAndTagView
      model: @model
    dragAndTagView.render()

  visitClicked: (ev) ->
    if $(ev.target).hasClass('search_domain')
      ev.preventDefault()
      router.navigate($(ev.target).attr('href'), trigger: true)

  deleteVisitClicked: (ev) ->
    ev.preventDefault()
    element = $(ev.currentTarget).parents('[data-id]').first()
    intervalId = $(ev.currentTarget).parents('.interval').data('id')
    interval = @model.get('history').get(intervalId)
    interval.findVisitById($(element).data('id')).destroy
      success: => element.remove()

  deleteGroupedVisitClicked: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    analyticsTracker.groupedVisitsDeletion()
    $(ev.currentTarget).siblings('.visits').children().each (i, visit) ->
      $(visit).find('.delete_visit').trigger('click')

    $(ev.currentTarget).parents('.visit').remove()

  deleteIntervalClicked: (ev) ->
    ev.preventDefault()
    analyticsTracker.timeIntervalDeletion()
    visitElements = $(ev.currentTarget).parents('.interval').children('.visits').children()
    $(visitElements).each (i, visit) ->
      setTimeout ->
        $(visit).children('.delete').trigger('click')
      , i * 10

      #$(ev.currentTarget).parents('.interval').remove()

  toggleGroupedVisitsClicked: (ev) ->
    ev.preventDefault()
    $(ev.currentTarget).parents('.visit')
      .toggleClass('expanded')

  getI18nValues: ->
    @t [
      'prompt_delete_button'
      'delete_time_interval_button'
      'no_visits_found'
      'expand_button'
      'collapse_button'
      'search_by_domain'
    ]
