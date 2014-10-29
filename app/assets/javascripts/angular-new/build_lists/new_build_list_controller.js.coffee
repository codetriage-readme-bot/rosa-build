NewBuildListController = (dataservice, $http) ->

  isBuildForMainPlatform = ->
    result = _.select(vm.platforms, (e) ->
      e.id is vm.build_for_platform_id
    )
    result.length is 1

  defaultSaveToRepository = ->
    return null unless vm.save_to_repositories
    return vm.save_to_repositories[0] unless vm.save_to_repository_id

    result = _.select(vm.save_to_repositories, (e) ->
      e.id is vm.save_to_repository_id
    )
    return vm.save_to_repositories[0] if result.length is 0
    result[0]

  defaultProjectVersion = ->
    return null unless vm.project_versions

    result = _.select(vm.project_versions, (e) ->
      e.name is vm.project_version_name
    )
    return vm.project_versions[0] if result.length is 0
    result[0]

  vm = this

  vm.selectSaveToRepository = ->
    setProjectVersion = ->
      return null unless vm.project_versions

      result = _.select(vm.project_versions, (e) ->
        e.name is vm.project_version_name
      )
      return vm.project_versions[0] if result.length is 0
      result[0]

    changeStatusRepositories = ->
      return unless vm.platforms
      _.each(vm.platforms, (pl) ->
        _.each(pl.repositories, (r) ->
          if pl.id isnt vm.build_for_platform_id
            r.checked = false
          if pl.id is vm.build_for_platform_id or
             (!vm.is_build_for_main_platform and vm.project_version.name is pl.name)
            r.checked = true if r.name == 'main' or r.name == 'base'
        )
      )

    updateDefaultArches = ->
      return unless vm.arches
      _.each(vm.arches, (a) ->
        a.checked = _.contains(vm.save_to_repository.default_arches, a.id)
      )

    getExtraRepos = ->
      return null if !vm.default_extra_repos || vm.is_build_for_main_platform

      result = _.select(vm.default_extra_repos, (e) ->
        e.platform_id is vm.build_for_platform_id
      )
      return result

    vm.build_for_platform_id = vm.save_to_repository.platform_id
    vm.is_build_for_main_platform = isBuildForMainPlatform()
    vm.project_version_name = vm.save_to_repository.platform_name

    vm.project_version = setProjectVersion() if vm.is_build_for_main_platform
    changeStatusRepositories()
    updateDefaultArches()
    vm.extra_repositories = getExtraRepos()
    true

  vm.selectProjectVersion = ->
    return unless vm.project_versions
    vm.selectSaveToRepository() unless vm.is_build_for_main_platform

  vm.selectExtraRepository = (item, model, label) ->
    vm.selected_extra_repository = item
    false

  vm.getExtraRepositories = (val) ->
    path = Routes.autocomplete_extra_repositories_autocompletes_path(
      {
        platform_id: vm.build_for_platform_id,
        term:        val
      }
    )

    return $http.get(path).then (response) ->
      response.data

  vm.removeExtraRepository = (id) ->
    vm.extra_repositories = _.reject(vm.extra_repositories, (repo) ->
      return repo.id is id
    )
    false

  vm.addExtraRepository = ->
    vm.extra_repositories = _.union(vm.extra_repositories, [vm.selected_extra_repository])
    false

  vm.selectExtraBuildList = (item, model, label) ->
    vm.selected_extra_build_list = item
    false

  vm.getExtraBuildLists = (val) ->
    path = Routes.autocomplete_extra_build_list_autocompletes_path(
      {
        platform_id: vm.build_for_platform_id,
        term:        val
      }
    )

    return $http.get(path).then (response) ->
      response.data

  vm.removeExtraBuildList = (id) ->
    vm.extra_build_lists = _.reject(vm.extra_build_lists, (repo) ->
      return repo.id is id
    )
    false

  vm.addExtraBuildList = ->
    vm.extra_build_lists = _.union(vm.extra_build_lists, [vm.selected_extra_build_list])
    false

  init = (dataservice) ->

    vm.build_for_platform_id      = dataservice.build_for_platform_id
    vm.platforms                  = dataservice.platforms
    vm.save_to_repositories       = dataservice.save_to_repositories
    vm.project_versions           = dataservice.project_versions

    vm.project_version_name       = dataservice.project_version
    vm.project_version            = defaultProjectVersion()
    vm.save_to_repository_id      = dataservice.save_to_repository_id
    vm.save_to_repository         = defaultSaveToRepository()

    vm.default_extra_repos        = dataservice.default_extra_repos
    vm.extra_repositories         = dataservice.extra_repos
    vm.extra_build_lists          = dataservice.extra_build_lists

    vm.arches                     = dataservice.arches

    vm.hidePlatform               = (platform) ->
      vm.is_build_for_main_platform and platform.id isnt vm.build_for_platform_id

    vm.is_build_for_main_platform = isBuildForMainPlatform()

  init(dataservice)
  vm.selectSaveToRepository() if !dataservice.build_list_id
  return true

angular
  .module("RosaABF")
  .controller "NewBuildListController", NewBuildListController

NewBuildListController.$inject = ['newBuildInitializer', '$http']
