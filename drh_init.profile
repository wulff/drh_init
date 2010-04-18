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
    'bulk_export',
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
//    'strongarm', we'll enable this after we're done setting variables
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
    'drh-content-batch' => 'Create content',
  );
}

/**
 * Perform any final installation tasks for this profile.
 */
function drh_init_profile_tasks(&$task, $url) {
  install_include(drh_init_profile_modules());

  if ('profile' == $task) {
    $task = 'drh-cck';

    system_theme_data();
    db_query("UPDATE {system} SET status = 1 WHERE type = 'theme' and name = '%s'", 'drh_jensen');
    db_query("UPDATE {system} SET status = 0 WHERE type = 'theme' and name ='%s'", 'garland');
    variable_set('theme_default', 'drh_jensen');

    variable_set('site_frontpage', 'forside');

    variable_set('page_manager_node_edit_disabled', FALSE);
    variable_set('page_manager_node_view_disabled', FALSE);

    $values = array();
    $values['category'] = 'Webmaster';
    $values['recipients'] = 'webmaster@drh.dk';
    $values['reply'] = '';
    $values['weight'] = 1;
    $values['selected'] = TRUE;
    drupal_write_record('contact', $values);

    $theme_settings = array (
      'toggle_logo' => 0,
      'toggle_name' => 1,
      'toggle_slogan' => 0,
      'toggle_mission' => 0,
      'toggle_node_user_picture' => 0,
      'toggle_comment_user_picture' => 0,
      'toggle_search' => 0,
      'toggle_favicon' => 1,
      'toggle_primary_links' => 1,
      'toggle_secondary_links' => 1,
      'toggle_node_info_profile' => 0,
      'toggle_node_info_event' => 0,
      'toggle_node_info_image' => 0,
      'toggle_node_info_facility' => 0,
      'toggle_node_info_course' => 0,
      'toggle_node_info_teaser' => 0,
      'toggle_node_info_topic' => 0,
      'toggle_node_info_news' => 0,
      'toggle_node_info_page' => 0,
      'default_logo' => 1,
      'logo_path' => '',
      'logo_upload' => '',
      'default_favicon' => 0,
      'favicon_path' => 'sites/all/themes/custom/drh_jensen/favicon.ico',
      'favicon_upload' => '',
    );
    variable_set('theme_settings', $theme_settings);
  }

  switch ($task) {
    case 'drh-cck':
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
        'title' => st('Create taxonomies.'),
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

    case 'drh-content':
      if (file_exists('./sites/default/files/default.jpg')) {
        unlink('./sites/default/files/default.jpg');
      }
      install_upload_file('./profiles/drh_init/images/default.jpg', array(), 'sites/default/files', FILE_EXISTS_RENAME, 'image/jpeg');

      if (file_exists('./sites/default/files/teaser_on.jpg')) {
        unlink('./sites/default/files/teaser_on.jpg');
      }
      install_upload_file('./profiles/drh_init/images/teaser_on.jpg', array(), 'sites/default/files', FILE_EXISTS_RENAME, 'image/jpeg');

      if (file_exists('./sites/default/files/teaser_off.jpg')) {
        unlink('./sites/default/files/teaser_off.jpg');
      }
      install_upload_file('./profiles/drh_init/images/teaser_off.jpg', array(), 'sites/default/files', FILE_EXISTS_RENAME, 'image/jpeg');

      $batch = array(
        'operations' => array(),
        'finished' => '_drh_init_content_batch_finished',
        'title' => st('Create content.'),
        'error_message' => st('The installation has encountered an error.'),
      );

      $types = file_scan_directory('./profiles/drh_init/content', '\.inc$', array('.', '..', 'CVS', '.svn', '.git'), 0, TRUE, 'name');

      foreach (array('teaser', 'page', 'topic', 'image') as $name) {
        if (isset($types[$name])) {
          include $types[$name]->filename;
          $batch['operations'][] = array('_drh_init_create_nodes', array($nodes));
          unset($types[$name]);
        }
      }
      foreach ($types as $name => $file) {
        include $file->filename;
        $batch['operations'][] = array('_drh_init_create_nodes', array($nodes));
      }

      variable_set('install_task', 'drh-content-batch');

      batch_set($batch);
      batch_process($url, $url);

      break;
    case 'drh-content-batch':
      include_once 'includes/batch.inc';
      return _batch_page();
      break;

    case 'drh-finalize':
      $item = array('link_path' => 'node/8', 'link_title' => 'Om skolen', 'menu_name' => 'primary-links', 'weight' => 1);
      $mlid = menu_link_save($item);
        $item = array('link_path' => 'node/7', 'link_title' => 'Praktisk', 'menu_name' => 'primary-links', 'weight' => 1, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/6', 'link_title' => 'Hverdagen', 'menu_name' => 'primary-links', 'weight' => 4, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/5', 'link_title' => 'Forlag', 'menu_name' => 'primary-links', 'weight' => 6, 'plid' => $mlid);
        menu_link_save($item);
      $item = array('link_path' => 'node/11', 'link_title' => 'Musiklinie', 'menu_name' => 'primary-links', 'weight' => 2);
      $mlid = menu_link_save($item);
        $item = array('link_path' => 'node/10', 'link_title' => 'Bas', 'menu_name' => 'primary-links', 'weight' => 1, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/15', 'link_title' => 'Guitar', 'menu_name' => 'primary-links', 'weight' => 2, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/13', 'link_title' => 'Sang', 'menu_name' => 'primary-links', 'weight' => 3, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/16', 'link_title' => 'Blæser', 'menu_name' => 'primary-links', 'weight' => 4, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/14', 'link_title' => 'Klaver', 'menu_name' => 'primary-links', 'weight' => 5, 'plid' => $mlid);
        menu_link_save($item);
        $item = array('link_path' => 'node/12', 'link_title' => 'Trommer', 'menu_name' => 'primary-links', 'weight' => 6, 'plid' => $mlid);
        menu_link_save($item);
      $item = array('link_path' => 'node/19', 'link_title' => 'Tekniklinie', 'menu_name' => 'primary-links', 'weight' => 3);
      $mlid = menu_link_save($item);
      $item = array('link_path' => 'node/18', 'link_title' => 'Sang- og producerlinie', 'menu_name' => 'primary-links', 'weight' => 4);
      $mlid = menu_link_save($item);
      $item = array('link_path' => 'node/17', 'link_title' => 'Sommerkurser', 'menu_name' => 'primary-links', 'weight' => 5);
      $mlid = menu_link_save($item);
      $item = array('link_path' => 'kontakt', 'link_title' => 'Kontakt', 'menu_name' => 'primary-links', 'weight' => 6);
      $mlid = menu_link_save($item);
        $item = array('link_path' => 'node/9', 'link_title' => 'Kort', 'menu_name' => 'primary-links', 'weight' => 1, 'plid' => $mlid);
        menu_link_save($item);

      // create secondary navigation menu block
      variable_set('menu_block_1_admin_title', 'Sekundær navigation');
      variable_set('menu_block_1_depth', 0);
      variable_set('menu_block_1_expanded', 0);
      variable_set('menu_block_1_follow', 0);
      variable_set('menu_block_1_level', 2);
      variable_set('menu_block_1_parent', 'primary-links:0');
      variable_set('menu_block_1_sort', 0);
      variable_set('menu_block_1_title_link', 0);
      variable_set('menu_block_ids', array(1));

      // lightbox
      variable_set('lightbox2_node_link_target', 0);
      variable_set('lightbox2_node_link_text', 'Vis billede i fuld størrelse');
      variable_set('lightbox2_download_link_text', '');
      variable_set('lightbox2_image_count_str', 'Billede !current af !total');
      variable_set('lightbox2_page_count_str', 'Side !current af !total');
      variable_set('lightbox2_video_count_str', 'Video !current af !total');
      variable_set('lightbox2_disable_resize', 1);
      variable_set('lightbox2_imagefield_group_node_id', 1);
      variable_set('lightbox2_imagefield_use_node_title', 1);
      variable_set('lightbox2_js_location', 'footer');
      variable_set('lightbox2_disable_close_click', 1);
      variable_set('lightbox2_border_size', 5);
      variable_set('lightbox2_box_color', 'fff');
      variable_set('lightbox2_font_color', '000');
      variable_set('lightbox2_top_position', 80);

      // configure default input format
      db_query("UPDATE {filter_formats} SET name = 'Default' WHERE format = 1");
      db_query("DELETE FROM {filter_formats} WHERE format = 2");
      db_query("DELETE FROM {filters} WHERE format = 2");

      install_set_filter(1, 'markdown', 0, -10);
      install_set_filter(1, 'filter', 0, -9); // html
      install_set_filter(1, 'filter', 1, -8); // line break
      install_set_filter(1, 'filter', 2, -7); // url
      install_set_filter(1, 'filter', 3, -6); // html corrector
      install_set_filter(1, 'typogrify', 0, -5);

      variable_set('allowed_html_1', '<a> <em> <strong> <cite> <code> <ul> <ol> <li> <dl> <dt> <dd> <h2> <h3> <h4>');
      variable_set('typogrify_is_widont_on_1', 0);

      // date and time
      variable_set('date_default_timezone_name', 'Europe/Copenhagen');
      variable_set('configurable_timezones', 0);
      variable_set('date_first_day', 1);

      variable_set('date_format_long', 'l, j F, Y - H:i');
      variable_set('date_format_medium', 'D, d/m/Y - H:i');
      variable_set('date_format_short', 'd/m/Y - H:i');

      // users & roles
      install_add_role('administrator');

      $rid = install_get_rid('anonymous user');
      install_add_permissions($rid, array('access comments', 'access site-wide contact form', 'view imagecache grid-16', 'view imagecache grid-9-crop', 'view imagecache lightbox', 'view imagecache thumb_front', 'view imagecache thumb_node'));

      $rid = install_get_rid('authenticated user');
      install_add_permissions($rid, array('access comments', 'access site-wide contact form', 'view imagecache grid-16', 'view imagecache grid-9-crop', 'view imagecache lightbox', 'view imagecache thumb_front', 'view imagecache thumb_node'));

      install_add_user('wulff', '1234', 'wulff@ratatosk.net', array('administrator'), 1);
      install_add_user('hans', '1234', 'hjh@drh.dk', array('administrator'), 1);

      variable_set('views_no_hover_links', TRUE);
      variable_set('ctools_content_all_views', FALSE);

      // enable strongarm
      _drupal_install_module('strongarm');
      module_enable(array('strongarm'));

      $task = 'profile-finished';

      break;
  }
}

/**
 * Perform any final installation tasks for this profile.
 */
function drh_init_profile_final() {
  variable_set('foo', TRUE);
}

/**
 * Implementation of hook_form_alter().
 */
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
  variable_set('install_task', 'drh-content');
}

function _drh_init_content_batch_finished() {
  variable_set('install_task', 'drh-finalize');
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

function _drh_init_create_nodes($nodes) {
//  @eval($content);

  if (isset($nodes) && is_array($nodes)) {
    foreach ($nodes as $nid => $node) {
      $default = array(
        'nid' => NULL,
        'title' => '-- no title--',
        'body' => NULL,
        'type' => 'page',
        'teaser' => NULL,
        'log' => '',
        'created' => '',
        'format' => 1, // TODO: use the format containing markdown
        'uid' => 1,
      );
      $node = array_merge($default, $node);

      $node = (object) $node;
      node_save($node);
    }
  }
}
