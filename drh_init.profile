<?php
// $Id$

/* --- HOOKS ---------------------------------------------------------------- */

/**
 * Return an array of the modules to be enabled when this profile is installed.
 */
function drh_init_profile_modules() {
  return array(
    // core - required
    'block',
    'filter',
    'node',
    'system',
    'user',

    // core - optional
    'comment',
    'contact',
    'dblog',
    'help',
    'locale',
    'menu',
    'path',
    'taxonomy',
    'update',

    // contrib
    'views',
    'active_tags',
    'active_tags_popular',
    'admin_menu',
    'advanced_help',
    'calendar',
    'content',
    'content_copy',
    'ctools',
    'date',
    'date_api',
    'date_locale',
    'date_popup',
    'demo',
    'devel',
    'embed_gmap',
    'filefield',
    'filefield_paths',
    'fieldgroup',
    'globalredirect',
    'imageapi',
    'imageapi_gd',
    'imagecache',
    'imagecache_ui',
    'imagefield',
    'install_profile_api',
    'jquery_ui',
    'l10n_client',
    'lightbox2',
    'link',
    'markdown',
    'menu_block',
    'nodeformcols',
    'nodereference',
    'number',
    'optionwidgets',
    'page_manager',
    'panels',
    'panels_mini',
    'path_redirect',
    'pathauto',
    'primary_term',
    'search404',
    'strongarm',
    'text',
    'token',
    'transliteration',
    'typogrify',
    'views_content',
    'views_export',
    'views_ui',

    // custom
    'drh_core',
    'drh_utility',
  );
}

/**
 * Return a description of the profile for the initial installation screen.
 */
function drh_init_profile_details() {
  return array(
    'name' => 'Den Rytmiske Højskole',
    'description' => 'Installation profile for drh.dk.'
  );
}

/**
 * Return a list of tasks that this profile supports.
 */
function drh_init_profile_task_list() {
  return array(
    'drh-cck-batch' => 'Create content types',
    'drh-taxonomy-batch' => 'Create taxonomies',
  );
}

/**
 * Perform any final installation tasks for this profile.
 */
function drh_init_profile_tasks(&$task, $url) {
  install_include(drh_init_profile_modules());

  switch ($task) {
    case 'profile':
      $batch = array(
        'operations' => array(),
        'finished' => '_drh_init_cck_batch_finished',
        'title' => st('Create content types.'),
        'error_message' => st('The installation has encountered an error.'),
      );

      $types = file_scan_directory('./profiles/drh_init/cck', '\.inc$', array('.', '..', 'CVS', '.svn', '.git'), 0, TRUE, 'name');
      foreach ($types as $name => $file) {
        $content = file_get_contents($file->filename);
        $batch['operations'][] = array('_drh_init_content_copy_import', array($content));
      }

      variable_set('install_task', 'drh-cck-batch');

      batch_set($batch);
      batch_process($url, $url);

      break;

    case 'drh-cck-batch':
      include_once 'includes/batch.inc';
      return _batch_page();
      break;

    case 'drh-taxonomy':
      $batch = array(
        'operations' => array(),
        'finished' => '_drh_init_taxonomy_batch_finished',
        'title' => st('Create content types.'),
        'error_message' => st('The installation has encountered an error.'),
      );

      $vocabs = file_scan_directory('./profiles/drh_init/taxonomy', '\.inc$', array('.', '..', 'CVS', '.svn', '.git'), 0, TRUE, 'name');
      foreach ($vocabs as $name => $file) {
        $content = file_get_contents($file->filename);
        $batch['operations'][] = array('_drh_init_taxonomy_export_import', array($content));
      }

      variable_set('install_task', 'drh-taxonomy-batch');

      batch_set($batch);
      batch_process($url, $url);

      break;

    case 'drh-taxonomy-batch':
      include_once 'includes/batch.inc';
      return _batch_page();
      break;

//    case 'drh-cck':
//      $types = file_scan_directory('./profiles/drh_init/cck', '\.inc$', array('.', '..', 'CVS', '.svn', '.git'), 0, TRUE, 'name');
//      install_content_copy_import_from_file('./profiles/drh_init/cck/news.inc');
//      foreach ($type as $name => $file) {
//        install_content_copy_import_from_file($file->filename);
//      }
//      $task = 'drh-taxonomy';
//      return;
//    case 'drh-taxonomy':
//      $task = 'profile-finished';
//      return;
  }
}

function drh_init_form_alter(&$form, $form_state, $form_id) {
  if ($form_id == 'install_configure') {
    $form['site_information']['site_name']['#default_value'] = 'drh.dk';
    $form['site_information']['site_mail']['#default_value'] = 'noreply@drh.dk';
    $form['admin_account']['account']['name']['#default_value'] = 'root';
    $form['admin_account']['account']['mail']['#default_value'] = 'root@drh.dk';

    $form['admin_account']['account']['pass']['#type'] = 'value';
    $form['admin_account']['account']['pass']['#value'] = '1234';

    $form['admin_account']['account']['pass_help']['#value'] = '<p><strong>'. t('The admin password has been set automatically!') .'</strong></p>';
  }
}

/* --- UTILITY -------------------------------------------------------------- */

function _drh_init_cck_batch_finished() {
  variable_set('install_task', 'drh-taxonomy');
}

function _drh_init_taxonomy_batch_finished() {
  variable_set('install_task', 'profile-finished');
}

function _drh_init_content_copy_import($content) {
  $form_state = array();
  $form = content_copy_import_form($form_state, $type_name);

  $form_state['values']['type_name'] = '<create>';
  $form_state['values']['macro'] = $content;
  $form_state['values']['op'] = t('Import');

  content_copy_import_form_submit($form, $form_state);
}

function _drh_init_taxonomy_export_import($content) {
  $form_state = array(
    'values' => array(
      'op' => t('Import'),
      'import_data' => $content,
    ),
  );

  module_load_include('inc', 'taxonomy_export', 'taxonomy_export.pages');

  if (_taxonomy_export_prepare_import_data($form_state['values']['import_data'])) {
    taxonomy_export_import_submit(array(), $form_state);
  }
}
