#!/usr/bin/python2


KEY_LOCAL_LOG = 'local-log'
KEY_TYPE = 'type'
KEY_ABSPATH = 'abspath'
KEY_FIELDS = 'fields'
KEY_COLUMN = 'column'
KEY_VALUE = 'value'
KEY_INDEX = 'index'
KEY_PRESET = 'preset'


TYPE_TEXT = 'text'
TYPE_SQLITE = 'sqlite'


FMT_TEXT = 'file("{abspath}" template("$PRIORITY\\t$YEAR/$MONTH/$DAY $HOUR:$MIN:$SEC\\t$MESSAGE\\n"));'
FMT_SQLITE = '''sql(
        type(sqlite3)
        database("{abspath}")
        table("logs")
        columns(
            {columns}
        )
        values(
            {values}
        )
        indexes(
            {indexes}
        )
        null("@@NULL@@")
        flags(explicit-commits)
        flush-lines(10000)
        flush_timeout(100)
        log_fifo_size(50000)
    );'''


DEFAULT_FIELDS = [
    {
        'column': 'id integer primary key',
        'value': '@@NULL@@',
        'index': True,
    },
    {
        'column': 'time int default NULL',
        'value': '$UNIXTIME',
        'index': True,
    },
    {
        'column': 'level text default NULL',
        'value': '$LEVEL',
        'index': True,
    },
    {
        'column': 'username text default NULL',
        'value': '$USERNAME',
        'index': True,
    },
    {
        'column': 'msg text default NULL',
        'value': '$MESSAGE',
    }
]

# mapping: field name -> default field info object
PRESETS = {}


def validate_synolog_conf(synolog_conf):
    if KEY_LOCAL_LOG not in synolog_conf.conf:
        return True

    local_log = synolog_conf.conf[KEY_LOCAL_LOG]

    if type(local_log) is not dict:
        return False

    if KEY_TYPE not in local_log:
        return False
    if KEY_ABSPATH not in local_log:
        return False

    if type(local_log[KEY_TYPE]) is not unicode:
        return False
    if type(local_log[KEY_ABSPATH]) is not unicode:
        return False

    if local_log[KEY_TYPE] not in [TYPE_TEXT, TYPE_SQLITE]:
        return False

    if local_log[KEY_TYPE] == TYPE_SQLITE and KEY_FIELDS in local_log:
        if type(local_log[KEY_FIELDS]) is not list:
            return False
        for field in local_log[KEY_FIELDS]:
            if type(field) is not dict:
                return False
            if KEY_PRESET in field:
                if type(field[KEY_PRESET]) is not unicode:
                    return False
                if field[KEY_PRESET] not in PRESETS:
                    return False
            else:
                if KEY_COLUMN not in field:
                    return False
                if KEY_VALUE not in field:
                    return False
                if type(field[KEY_COLUMN]) is not unicode:
                    return False
                if type(field[KEY_VALUE]) is not unicode:
                    return False
                if KEY_INDEX in field and type(field[KEY_INDEX]) is not bool:
                    return False

    return True


def generate_syslog_ng_conf(synolog_conf):
    if not synolog_conf.is_key_enabled(KEY_LOCAL_LOG):
        return None

    local_log = synolog_conf.conf[KEY_LOCAL_LOG]

    conf = []

    log_type = local_log[KEY_TYPE]
    log_abspath = local_log[KEY_ABSPATH]
    log_fields = local_log[KEY_FIELDS] if KEY_FIELDS in local_log else DEFAULT_FIELDS

    content = _render_content(log_type, log_abspath, log_fields)

    conf.append({
        'type': 'destination',
        'name': 'd_local_{}'.format(synolog_conf.app_id),
        'content': [
            content
        ]
    })

    return conf


def _render_content(log_type, log_abspath, log_fields):
    if log_type == TYPE_TEXT:
        return _render_text_content(log_abspath)
    if log_type == TYPE_SQLITE:
        return _render_sqlite_content(log_abspath, log_fields)
    assert False


def _render_text_content(log_abspath):
    return FMT_TEXT.format(abspath=log_abspath)


def _render_sqlite_content(log_abspath, log_fields):
    columns = []
    values = []
    indexes = []

    for log_field in log_fields:
        if KEY_PRESET in log_field:
            log_field = PRESETS[log_field[KEY_PRESET]]

        columns.append(log_field[KEY_COLUMN])
        values.append(log_field[KEY_VALUE])

        if KEY_INDEX in log_field and log_field[KEY_INDEX]:
            indexes.append(_extract_field_name(log_field))

    def join_strs(strs):
        SEPARATOR = ',\n' + '    ' * 3
        return SEPARATOR.join(['"{}"'.format(str_) for str_ in strs])

    return FMT_SQLITE.format(abspath=log_abspath,
                             columns=join_strs(columns),
                             values=join_strs(values),
                             indexes=join_strs(indexes))


def _extract_field_name(field):
    column = field[KEY_COLUMN]
    tokens = column.split()
    return tokens[0]


def _prepare_presets():
    for default_field in DEFAULT_FIELDS:
        field_name = _extract_field_name(default_field)
        PRESETS[field_name] = default_field


_prepare_presets()
