#include <glib-unix.h>
#include <glib/gstdio.h>
#include <gst/gst.h>
//#include <gtk/gtk.h>
#define g_debug printf

#include <glib.h>


static GstElement *debug_runtime_factory_make(const gchar *el, const gchar *name)
{
  GstElement *bin;
  GError *error = NULL;
  g_print("new bin: %s, name:%s\n", el, name);

  /* Create bin, such as. then add to pipeline later.
   * gst_parse_bin_from_description( \
   *  "tee name=t0 ! queue ! autovideosink t0. ! filesink location=/tmp/test.bin", \
   *   TRUE, &error)
   */
  g_return_val_if_fail((bin = gst_parse_bin_from_description(el, TRUE, &error)) != NULL, NULL);
  if (bin == NULL || error != NULL) {
        GST_ERROR("create enc_audio_bin failed\n");
        return NULL;
  }
  g_object_set(bin, "name",  name, NULL);
  return bin;
}
#if 0
/*
 * Add property to element @el(i.e: filesink location=/tmp/data.bin
 * @key - key name: eg, "location"
 * @val - value string: eg "/tmp/data.bin"
 */
static gboolean debug_runtime_element_set_property(GstElement *el, const char *key, const char *val)
{
  GParamSpec *propspecs;
  GValue value = G_VALUE_INIT;

  if ((propspecs = g_object_class_find_property(G_OBJECT_GET_CLASS (el), key)) == NULL)
    return FALSE;
  g_printerr("%s %d: PTM\n", __FUNCTION__, __LINE__);

  g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (propspecs));

  g_return_val_if_fail(gst_value_deserialize(&value, val), NULL);
  g_object_set_property (G_OBJECT (el), key, &value);
  g_printerr("%s %d: PTM\n", __FUNCTION__, __LINE__);

  return TRUE;
}
#endif
static gchar *key_get_locale(const gchar * key)
{
  gchar *locale;

  locale = g_strrstr(key, "[");

  if (locale && strlen(locale) <= 2)
    locale = NULL;

  if (locale)
    locale = g_strndup(locale + 1, strlen(locale) - 2);

  return locale;
}

GSList *Gst_slist_head;

struct gst_element_hash {
  gchar name[128];	/* name of bin see debug_runtime_factory_make()               */
  gchar parent[128];	/* Parent element name of bin, for link/unlunk point(element) */
  GSList *elements;	/* The list of bins       */
  GSList *it;		/* Iterator of @elements  */
};

static struct gst_element_hash * gst_element_hash_new(gchar *name)
{
  struct gst_element_hash * h =  g_new(struct gst_element_hash, 1);
  strcpy(h->name, name);
  h->elements = NULL;
  h->parent[0] = '\0';
  h->it = NULL;
  return h;
}

static void dump_gst_element_hashs(struct gst_element_hash *h)
{
  GSList *iterator = NULL;
  printf("Dump hash\n");
  for (iterator = h; iterator; iterator = iterator->next) {
    struct gst_element_hash *p = (struct gst_element_hash *)iterator->data;
    printf(" %p: %s, parent: %s\n", (void *) iterator->data, p->name, p->parent );
    for ( GSList *ep = p->elements;ep; ep = ep->next) {
      printf("  Element: %p\n", (void *) ep->data);
    }
  }
  printf("\n");
}

static int fn_relink_bin(GstElement *add_bin,  gchar *name, gchar *parent, void *userdata)
{
  GstElement *remove_el, *indicator = NULL;
  GstElement *pipeline = (GstElement *)userdata;
  // FIXME: leak without relese @demosink
  g_return_val_if_fail((indicator = gst_bin_get_by_name(GST_BIN (pipeline), parent)) != NULL, NULL);
  g_return_val_if_fail((remove_el = gst_bin_get_by_name (GST_BIN (pipeline), name)) != NULL, NULL);
  static int re = 0;
  g_printerr("Get Name:%s, parent: %s\n", name, parent);
  g_printerr("Get ref el: %d\n", ((GObject *) remove_el)->ref_count);

  g_return_val_if_fail(gst_bin_remove (GST_BIN (pipeline), remove_el), NULL);
  //gst_bin_remove (GST_BIN (pipeline), remove_el);
  g_return_val_if_fail(gst_bin_add(GST_BIN (pipeline), add_bin), NULL);
  gst_element_unlink(indicator, remove_el);
  g_return_val_if_fail(gst_element_link(indicator, add_bin), NULL);
  g_printerr("Get ref el: %d\n", ((GObject *) remove_el)->ref_count);
  g_printerr("Get ref indicator: %d\n", ((GObject *) indicator)->ref_count);
  g_printerr("Get ref demosink : %d\n", ((GObject *) add_bin)->ref_count);
  gst_object_unref(indicator);
  gst_element_set_state (remove_el, GST_STATE_NULL);
  /* TODO: work around, how to remove first element from pipelne_bin properly */
  re++;
  if (re > 3)
    gst_object_unref(remove_el);
  g_printerr("unref\nGet ref remvoed bin: %d\n", ((GObject *) remove_el)->ref_count);
  g_printerr("Get ref indicator: %d\n", ((GObject *) indicator)->ref_count);
  return 0;
out:
  if (remove_el)
     gst_object_unref (remove_el);
  if (indicator)
     gst_object_unref (indicator);
  return;
}

static int __list_roundtrip(struct gst_element_hash *h, int (*fn)(GstElement *,  gchar *, gchar *, void *), void *userdata)
{
  GSList *iterator = NULL;
  GSList *ep = NULL;
  static int nx = 0;

  for (iterator = h; iterator; iterator = iterator->next) {
    struct gst_element_hash *p = (struct gst_element_hash *)iterator->data;
    printf(" %p: %s, parent: %s\n", (void *) iterator->data, p->name, p->parent );
    /* Get next element object */
    if (p->it) {
      /* Call change element */
      printf("========= %d change to element (%p, %s, %s)\n", nx++, p->it->data, p->name, p->parent);
      if (userdata)
        g_assert(!fn(p->it->data, p->name, p->parent, userdata));
    }
    /* point to next element */
    p->it = p->it->next;
    if (!p->it)
      p->it = p->elements;   
  }
  printf("\n");
  return 0;
}

int list_roundtrip(void *userdata)
{
  return __list_roundtrip(Gst_slist_head, fn_relink_bin, userdata);
}
int dyanmic_elements_init(gchar *ini)
{
  GKeyFile *key_file;
  GError *error = NULL;
  guint group, key;

  key_file = g_key_file_new();

  if (!g_key_file_load_from_file(key_file,
				 ini,
				 G_KEY_FILE_KEEP_COMMENTS |
				 G_KEY_FILE_KEEP_TRANSLATIONS, &error)) {
    g_debug("%s", error->message);
    printf("PTM %s %d\n", __FUNCTION__, __LINE__);
    return 0;
  }
  //g_log(G_LOG_DOMAIN, G_LOG_LEVEL_INFO, "Test log (info level)");
  //g_log(G_LOG_DOMAIN, G_LOG_LEVEL_ERROR, "Test log (info level)");
  g_log(G_LOG_DOMAIN, G_LOG_LEVEL_WARNING, "Test log (info level)");
  //export G_MESSAGES_DEBUG=
  //g_error("ERROR PTM");
  g_info("INFO PTM\n");
  g_debug("DEBUG PTM\n");
  gsize num_groups, num_keys;
  gchar **groups, **keys, *value;
  GstElement *el_new;
  groups = g_key_file_get_groups(key_file, &num_groups);
  for (group = 0; group < num_groups; group++) {
    struct gst_element_hash *ne;

    g_debug("group %u/%u: \t%s\n", group, num_groups - 1, groups[group]);
    ne = gst_element_hash_new(groups[group]);
    Gst_slist_head = g_slist_append(Gst_slist_head, ne);
    
    keys = g_key_file_get_keys(key_file, groups[group], &num_keys, &error);
    
    for (key = 0; key < num_keys; key++) {
      gchar *locale;
      value = g_key_file_get_value(key_file,
				   groups[group], keys[key], &error);
      g_debug("\t\tkey %u/%u: \t%s => %s\n", key,
	      num_keys - 1, keys[key], value);

      if (strncmp(keys[key], "element", strlen("element")) == 0) {
        g_debug("\t\tGet element: [%s]\n", value);
        el_new = debug_runtime_factory_make(value, groups[group]);
        //((struct gst_element_hash *)Gst_slist_head->data)->elements = g_slist_append(((struct gst_element_hash *)Gst_slist_head->data)->elements, el_new);
        ne->elements = g_slist_append(ne->elements, el_new);
	if (ne->it == NULL)
		ne->it = ne->elements;		/* iterator only init at first element */
      } else if (strcmp(keys[key], "parent") == 0) {
	printf("\t\tGet parent:%s\n", value);
        strcpy(ne->parent, value);
      } else {
        g_debug("\t\tunknow key:%s=%s\n", keys[key], value);
        //debug_runtime_element_set_property(el_new, keys[key], value);
      }
    }
  }
  return 0;
}
#ifdef __KEY_FILE_DEBUG__
static void dummy_gst_init(int argc, char *argv[])
{
  gst_init (&argc, &argv);
}
int main(int argc, char *argv)
{
  GKeyFile *key_file;
  GError *error;

  dummy_gst_init(argc, argv);

  key_file = g_key_file_new();
  error = NULL;

  guint group, key;
  dyanmic_elements_init("./test.ini");
  dump_gst_element_hashs(Gst_slist_head);

  list_roundtrip(NULL);
  list_roundtrip(NULL);
  list_roundtrip(NULL);
  list_roundtrip(NULL);
  list_roundtrip(NULL);
  list_roundtrip(NULL);
  return 0;
}
#endif
