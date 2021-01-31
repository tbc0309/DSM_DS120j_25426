/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.API");SYNO.API.GetErrors=function(){var a={};a.minCustomeError=400;a.common={0:_T("common","commfail"),100:_T("common","error_system"),101:"Bad Request",102:"No Such API",103:"No Such Method",104:"Not Supported Version",105:_T("error","error_privilege_not_enough"),106:_T("error","error_timeout"),107:_T("login","error_interrupt"),108:_T("user","user_file_upload_fail"),109:_T("error","error_error_system"),110:_T("error","error_error_system"),111:_T("error","error_error_system"),112:"Stop Handling Compound Request",113:"Invalid Compound Request",114:_T("error","error_invalid"),115:_T("error","error_invalid"),116:_JSLIBSTR("uicommon","error_demo"),117:_T("error","error_error_system"),118:_T("error","error_error_system"),122:_T("error","error_privilege_not_enough"),123:_T("error","error_privilege_not_enough"),124:_T("error","error_privilege_not_enough"),125:_T("error","error_timeout"),126:_T("error","error_privilege_not_enough"),127:_T("error","error_privilege_not_enough"),160:_T("error","error_privilege_not_enough")};a.core={402:_T("share","no_such_share"),403:_T("error","error_invalid"),404:_T("error","error_privilege_not_enough"),1101:_T("error","error_subject"),1102:_T("firewall","firewall_restore_failed"),1103:_T("firewall","firewall_block_admin_client"),1104:_T("firewall","firewall_rule_exceed_max_number"),1105:_T("firewall","firewall_rule_disable_fail"),1198:_T("common","version_not_support"),1201:_T("error","error_subject"),1202:_T("firewall","firewall_tc_ceil_exceed_system_upper_bound"),1203:_T("firewall","firewall_tc_max_ceil_too_large"),1204:_T("firewall","firewall_tc_restore_failed"),1301:_T("error","error_subject"),1302:_T("firewall","firewall_dos_restore_failed"),1402:_T("service","service_ddns_domain_load_error"),1410:_T("service","service_ddns_operation_fail"),1500:_T("common","error_system"),1501:_T("common","error_apply_occupied"),1502:_T("routerconf","routerconf_external_ip_warning"),1503:_T("routerconf","routerconf_require_gateway"),1504:_T("routerconf","dns_setting_no_response"),1510:_T("routerconf","routerconf_update_db_failed"),1521:_T("routerconf","routerconf_exceed_singel_max_port"),1522:_T("routerconf","routerconf_exceed_combo_max_port"),1523:_T("routerconf","routerconf_exceed_singel_range_max_port"),1524:_T("routerconf","routerconf_exceed_max_rule"),1525:_T("routerconf","routerconf_port_conflict"),1526:_T("routerconf","routerconf_add_port_failed"),1527:_T("routerconf","routerconf_apply_failed"),1528:_T("routerconf","protocol_on_router_not_enabled"),1530:_T("routerconf","routerconf_syntax_version_error"),1600:_T("error","error_error_system"),1601:_T("error","error_error_system"),1602:_T("error","error_error_system"),1701:_T("error","error_port_conflict"),1702:_T("error","error_file_exist"),1703:_T("error","error_no_path"),1704:_T("error","error_error_system"),1706:_T("error","error_volume_ro"),1903:_T("error","error_port_conflict"),1904:_T("error","error_port_conflict"),1905:_T("ftp","ftp_annoymous_root_share_invalid"),1951:_T("error","error_port_conflict"),2001:_T("error","error_error_system"),2002:_T("error","error_error_system"),2101:_T("error","error_error_system"),2102:_T("error","error_error_system"),2201:_T("error","error_error_system"),2202:_T("error","error_error_system"),2301:_T("error","error_invalid"),2303:_T("error","error_port_conflict"),2331:_T("nfs","nfs_key_wrong_format"),2332:_T("user","user_file_upload_fail"),2371:_T("error","error_mount_point_nfs"),2372:_T("error","error_hfs_plus_mount_point_nfs"),2401:_T("error","error_error_system"),2402:_T("error","error_error_system"),2403:_T("error","error_port_conflict"),2500:_T("error","error_unknown_desc"),2502:_T("error","error_invalid"),2503:_T("error","error_error_system"),2504:_T("error","error_error_system"),2505:_T("error","error_error_system"),2601:_T("network","domain_name_err"),2602:_T("network","domain_dns_name_err"),2603:_T("network","domain_kdc_ip_error"),2604:_T("network","error_badgname"),2605:_T("network","domain_unreachserver_err"),2606:_T("network","domain_port_unreachable_err"),2607:_T("network","domain_password_err"),2608:_T("network","domain_acc_revoked_ads"),2609:_T("network","domain_acc_revoked_rpc"),2610:_T("network","domain_acc_err"),2611:_T("network","domain_notadminuser"),2612:_T("network","domain_change_passwd"),2613:_T("network","domain_check_kdcip"),2614:_T("network","domain_error_misc_rpc"),2615:_T("network","domain_join_err"),2616:_T("directory_service","warr_enable_samba"),2626:_T("directory_service","warr_db_not_ready"),2628:_T("directory_service","warr_synoad_exists"),2702:_T("network","status_connected"),2703:_T("network","status_disconnected"),2704:_T("common","error_occupied"),2705:_T("common","error_system"),2706:_T("ldap_error","ldap_invalid_credentials"),2707:_T("ldap_error","ldap_operations_error"),2708:_T("ldap_error","ldap_server_not_support"),2709:_T("domain","domain_ldap_conflict"),2710:_T("ldap_error","ldap_operations_error"),2712:_T("ldap_error","ldap_no_such_object"),2713:_T("ldap_error","ldap_protocol_error"),2714:_T("ldap_error","ldap_invalid_dn_syntax"),2715:_T("ldap_error","ldap_insufficient_access"),2716:_T("ldap_error","ldap_insufficient_access"),2717:_T("ldap_error","ldap_timelimit_exceeded"),2718:_T("ldap_error","ldap_inappropriate_auth"),2719:_T("ldap_error","ldap_smb2_enable_warning"),2721:_T("ldap_error","ldap_confidentiality_required"),2799:_T("common","error_system"),2800:_T("error","error_unknown_desc"),2801:_T("error","error_unknown_desc"),2900:_T("error","error_unknown_desc"),2901:_T("error","error_unknown_desc"),2902:_T("relayservice","relayservice_err_network"),2903:_T("relayservice","error_alias_server_internal"),2904:_T("relayservice","relayservice_err_alias_in_use"),2905:_T("pkgmgr","myds_error_account"),2906:_T("relayservice","error_alias_used_in_your_own"),3000:_T("error","error_unknown_desc"),3001:_T("error","error_unknown_desc"),3002:_T("relayservice","relayservice_err_resolv"),3003:_T("relayservice","myds_server_internal_error"),3004:_T("error","error_auth"),3005:_T("relayservice","relayservice_err_alias_in_use"),3006:_T("relayservice","myds_exceed_max_register_error"),3009:_T("error","error_unknown_desc"),3010:_T("myds","already_logged_in"),3013:_T("myds","error_migrate_authen"),3106:_T("user","no_such_user"),3107:_T("user","error_nameused"),3108:_T("user","error_nameused"),3109:_T("user","error_disable_admin"),3110:_T("user","error_too_much_user"),3111:_T("user","homes_not_found"),3112:_T("common","error_apply_occupied"),3113:_T("common","error_occupied"),3114:_T("user","error_nameused"),3115:_T("user","user_cntrmvdefuser"),3116:_T("user","user_set_fail"),3117:_T("user","user_quota_set_fail"),3118:_T("common","error_no_enough_space"),3119:_T("user","error_home_is_moving"),3121:_T("common","err_pass"),3122:_T("login","password_in_history"),3123:_T("login","password_too_common"),3124:_T("common","err_pass"),3130:_T("user","invalid_syntax_enclosed_trailing"),3131:_T("user","invalid_syntax_double_quote_in_middle"),3132:_T("user","invalid_syntax_not_double_quote_ending"),3191:_T("user","user_file_open_fail"),3192:_T("user","user_file_empty"),3193:_T("user","user_file_not_utf8"),3194:_T("user","user_upload_no_volume"),3202:_T("common","error_occupied"),3204:_T("group","failed_load_group"),3205:_T("group","failed_load_group"),3206:_T("group","error_nameused"),3207:_T("group","error_nameused"),3208:_T("group","error_badname"),3209:_T("group","error_toomanygr"),3210:_T("group","error_rmmember"),3217:_T("group","error_too_many_dir_admin"),3221:_T("share","error_too_many_acl_rules")+"("+_T("acl_editor","acl_rules_reach_limit_report").replace(/.*\//,"").trim().replace("_maxCount_","200")+")",3299:_T("common","error_system"),3301:_T("share","share_already_exist"),3302:_T("share","share_acl_volume_not_support"),3303:_T("share","error_encrypt_reserve"),3304:_T("share","error_volume_not_found"),3305:_T("share","error_badname"),3308:_T("common","err_pass"),3309:_T("share","error_toomanysh"),3313:_T("share","error_volume_not_found"),3314:_T("share","error_volume_read_only"),3319:_T("share","error_nameused"),3320:_T("share","share_space_not_enough"),3321:_T("share","error_too_many_acl_rules")+"("+_T("acl_editor","acl_rules_reach_limit_report").replace(/.*\//,"").trim().replace("_maxCount_","200")+")",3322:_T("share","mount_point_not_empty"),3323:_T("error","error_mount_point_change_vol"),3324:_T("error","error_mount_point_rename"),3326:_T("share","error_key_file"),3327:_T("share","share_conflict_on_new_volume"),3328:_T("share","get_lock_failed"),3329:_T("share","error_toomanysnapshot"),3330:_T("share","share_snapshot_busy"),3332:_T("backup","is_backing_up_restoring"),3334:_T("share","error_mount_point_restore"),3335:_T("share","share_cannot_move_fstype_not_support"),3336:_T("share","share_cannot_move_replica_busy"),3337:_T("snapmgr","snap_system_preserved"),3338:_T("share","error_mounted_encrypt_restore"),3340:_T("snapmgr","snap_restore_share_conf_err"),3341:_T("snapmgr","err_quota_is_not_enough"),3344:_T("keymanager","error_invalid_passphrase"),3345:_T("keymanager","error_used_keystore"),3400:_T("error","error_error_system"),3401:_T("error","error_error_system"),3402:_T("error","error_error_system"),3403:_T("app_privilege","error_no_such_user_or_group"),3500:_T("error","error_invalid"),3501:_T("common","error_badport"),3502:_T("error","error_port_conflict"),3503:_T("error","error_port_conflict"),3504:_T("error","error_port_conflict"),3505:_T("app_port_alias","err_fqdn_duplicated"),3510:_T("error","error_invalid"),3511:_T("app_port_alias","err_port_dup"),3550:_T("volume","volume_no_volumes"),3551:_T("error","error_no_shared_folder"),3552:String.format(_T("volume","volume_crashed_service_disable"),_T("common","web_station")),3553:_T("volume","volume_expanding_waiting"),3554:_T("error","error_port_conflict"),3555:_T("common","error_badport"),3603:_T("volume","volume_share_volumeno"),3604:_T("error","error_space_not_enough"),3605:_T("usb","usb_printer_driver_fail"),3606:_T("login","error_cantlogin"),3607:_T("common","error_badip"),3608:_T("usb","net_prntr_ip_exist_error"),3609:_T("usb","net_prntr_ip_exist_unknown"),3610:_T("common","error_demo"),3611:_T("usb","net_prntr_name_exist_error"),3700:_T("error","error_invalid"),3701:_T("status","status_not_available"),3702:_T("error","error_invalid"),3710:_T("status","status_not_available"),3711:_T("error","error_invalid"),3712:_T("cms","fan_mode_not_supported"),3720:_T("status","status_not_available"),3721:_T("error","error_invalid"),3730:_T("status","status_not_available"),3731:_T("error","error_invalid"),3740:_T("status","status_not_available"),3741:_T("error","error_invalid"),3750:_T("status","status_not_available"),3751:_T("error","error_invalid"),3760:_T("status","status_not_available"),3761:_T("error","error_invalid"),3800:_T("error","error_invalid"),3801:_T("error","error_invalid"),4000:_T("error","error_invalid"),4001:_T("error","error_error_system"),4002:_T("dsmoption","error_format"),4003:_T("dsmoption","error_size"),4100:_T("error","error_invalid"),4101:_T("error","error_invalid"),4102:_T("app_port_alias","err_alias_refused"),4103:_T("app_port_alias","err_alias_used"),4104:_T("app_port_alias","err_port_used"),4105:_T("app_port_alias","err_port_used"),4106:_T("app_port_alias","err_port_used"),4107:_T("app_port_alias","err_fqdn_duplicated"),4154:_T("app_port_alias","err_fqdn_duplicated"),4155:_T("app_port_alias","err_port_used"),4156:_T("app_port_alias","err_invalid_backend_host"),4164:_T("app_port_alias","err_invalid_header_name"),4165:_T("app_port_alias","err_invalid_header_value"),4166:_T("app_port_alias","err_header_name_duplicated"),4168:_T("app_port_alias","err_proxy_timeout"),4169:_T("app_port_alias","err_proxy_timeout"),4170:_T("app_port_alias","err_proxy_timeout"),4300:_T("error","error_error_system"),4301:_T("error","error_error_system"),4302:_T("error","error_error_system"),4303:_T("error","error_invalid"),4304:_T("error","error_error_system"),4305:_T("error","error_error_system"),4306:_T("error","error_error_system"),4307:_T("error","error_error_system"),4308:_T("error","error_error_system"),4309:_T("error","error_invalid"),4310:_T("error","error_error_system"),4311:_T("network","interface_not_found"),4312:_T("tcpip","tcpip_ip_used"),4313:_T("tcpip","ipv6_ip_used"),4314:_T("tunnel","tunnel_conn_fail"),4315:_T("tcpip","ipv6_err_link_local"),4316:_T("network","error_applying_network_setting"),4317:_T("common","error_notmatch"),4319:_T("error","error_error_system"),4320:_T("vpnc","name_conflict"),4321:_T("service","service_illegel_crt"),4322:_T("service","service_illegel_key"),4323:_T("service","service_ca_not_utf8"),4324:_T("service","service_unknown_cipher"),4325:_T("vpnc","l2tp_conflict"),4326:_T("vpnc","vpns_conflict"),4327:_T("vpnc","ovpnfile_invalid_format"),4340:_T("background_task","task_processing"),4350:_T("tcpip","ipv6_invalid_config"),4351:_T("tcpip","ipv6_router_bad_lan_req"),4352:_T("tcpip","ipv6_router_err_enable"),4353:_T("tcpip","ipv6_router_err_disable"),4354:_T("tcpip","ipv6_no_public_ip"),4370:_T("ovs","ovs_not_support_bonding"),4371:_T("ovs","ovs_not_support_vlan"),4372:_T("ovs","ovs_not_support_bridge"),4373:_T("network","linkaggr_mode_inconsistent_err"),4380:_T("router_networktools","ping_target_invalid"),4381:_T("router_networktools","ping_timeout"),4382:_T("router_networktools","traceroute_target_invalid"),4500:_T("error","error_error_system"),4501:_T("error","error_error_system"),4502:_T("pkgmgr","pkgmgr_space_not_ready"),4503:_T("error","volume_creating"),4504:_T("pkgmgr","error_sys_no_space"),4506:_T("pkgmgr","noncancellable"),4520:_T("error","error_space_not_enough"),4521:_T("pkgmgr","pkgmgr_file_not_package"),4522:_T("pkgmgr","broken_package"),4529:_T("pkgmgr","pkgmgr_pkg_cannot_upgrade"),4530:_T("pkgmgr","error_occupied"),4531:_T("pkgmgr","pkgmgr_not_syno_publish"),4532:_T("pkgmgr","pkgmgr_unknown_publisher"),4533:_T("pkgmgr","pkgmgr_cert_expired"),4534:_T("pkgmgr","pkgmgr_cert_revoked"),4535:_T("pkgmgr","broken_package"),4540:_T("pkgmgr","pkgmgr_file_install_failed"),4541:_T("pkgmgr","upgrade_fail"),4542:_T("error","error_error_system"),4543:_T("pkgmgr","pkgmgr_file_not_package"),4544:_T("pkgmgr","pkgmgr_pkg_install_already"),4545:_T("pkgmgr","pkgmgr_pkg_not_available"),4548:_T("pkgmgr","install_version_less_than_limit"),4549:_T("pkgmgr","depend_cycle"),4570:_T("common","error_invalid_serial"),4580:_T("pkgmgr","pkgmgr_pkg_start_failed"),4581:_T("pkgmgr","pkgmgr_pkg_stop_failed"),4590:_T("pkgmgr","invalid_feed"),4591:_T("pkgmgr","duplicate_feed"),4592:_T("pkgmgr","duplicate_certificate"),4593:_T("pkgmgr","duplicate_certificate_sys"),4594:_T("pkgmgr","revoke_certificate"),4595:_T("service","service_illegel_crt"),4600:_T("error","error_error_system"),4601:_T("error","error_error_system"),4602:_T("notification","google_auth_failed"),4631:_T("error","error_error_system"),4632:_T("error","error_error_system"),4633:_T("error","error_error_system"),4634:_T("error","error_error_system"),4635:_T("error","error_error_system"),4661:_T("pushservice","error_update_ds_info"),4800:_T("error","error_invalid"),4801:_T("error","error_error_system"),4802:_T("error","error_error_system"),4803:_T("error","error_error_system"),4804:_T("error","error_error_system"),4900:_T("error","error_invalid"),4901:_T("error","error_error_system"),4902:_T("user","no_such_user"),4903:_T("report","err_dest_share_not_exist"),4904:_T("error","error_file_exist"),4905:_T("error","error_space_not_enough"),5000:_T("error","error_invalid"),5001:_T("error","error_invalid"),5002:_T("error","error_invalid"),5003:_T("error","error_invalid"),5004:_T("error","error_invalid"),5005:_T("syslog","err_server_disconnected"),5006:_T("syslog","service_ca_copy_failed"),5007:_T("syslog","service_ca_copy_failed"),5008:_T("error","error_invalid"),5009:_T("error","error_port_conflict"),5010:_T("error","error_invalid"),5011:_T("error","error_invalid"),5012:_T("syslog","err_name_conflict"),5100:_T("error","error_invalid"),5101:_T("error","error_invalid"),5102:_T("error","error_invalid"),5103:_T("error","error_invalid"),5104:_T("error","error_invalid"),5105:_T("error","error_invalid"),5106:_T("error","error_invalid"),5202:_T("update","error_apply_lock"),5203:_T("volume","volume_busy_waiting"),5205:_T("update","error_bad_dsm_version"),5206:_T("update","update_notice"),5207:_T("update","error_model"),5208:_T("update","error_apply_lock"),5209:_T("update","error_patch"),5211:_T("update","upload_err_no_space"),5213:_T("pkgmgr","error_occupied"),5214:_T("update","check_new_dsm_err"),5215:_T("error","error_space_not_enough"),5216:_T("error","error_fs_ro"),5217:_T("error","error_dest_no_path"),5219:_T("update","autoupdate_cancel_failed_running"),5220:_T("update","autoupdate_cancel_failed_no_task"),5221:_T("update","autoupdate_cancel_failed"),5222:_T("update","error_verify_patch"),5223:_T("update","error_updater_prehook_failed"),5300:_T("error","error_invalid"),5301:_T("user","no_such_user"),5510:_T("service","service_illegel_crt"),5511:_T("service","service_illegel_key"),5512:_T("service","service_illegal_inter_crt"),5513:_T("service","service_unknown_cypher"),5514:_T("service","service_key_not_match"),5515:_T("service","service_ca_copy_failed"),5516:_T("service","service_ca_not_utf8"),5517:_T("certificate","inter_and_crt_verify_error"),5518:_T("certificate","not_support_dsa"),5519:_T("service","service_illegal_csr"),5520:_T("backup","general_backup_destination_no_response"),5521:_T("certificate","err_connection"),5522:_T("certificate","err_server_not_match"),5523:_T("certificate","err_too_many_reg"),5524:_T("certificate","err_too_many_req"),5525:_T("certificate","err_mail"),5526:_T("s2s","err_invalid_param_value"),5527:_T("certificate","err_le_server_busy"),5528:_T("certificate","err_not_synoddns"),5529:_T("certificate","not_support_ecc"),5600:_T("error","error_no_path"),5601:_T("file","error_bad_file_content"),5602:_T("error","error_error_system"),5603:_T("texteditor","LoadFileFail"),5604:_T("texteditor","SaveFileFail"),5605:_T("error","error_privilege_not_enough"),5606:_T("texteditor","CodepageConvertFail"),5607:_T("texteditor","AskForceSave"),5608:_T("error","error_encryption_long_path"),5609:_T("error","error_long_path"),5610:_T("error","error_quota_not_enough"),5611:_T("error","error_space_not_enough"),5612:_T("error","error_io"),5613:_T("error","error_privilege_not_enough"),5614:_T("error","error_fs_ro"),5615:_T("error","error_file_exist"),5616:_T("error","error_no_path"),5617:_T("error","error_dest_no_path"),5618:_T("error","error_testjoin"),5619:_T("error","error_reserved_name"),5620:_T("error","error_fat_reserved_name"),5621:_T("texteditor","exceed_load_max"),5703:_T("time","ntp_service_disable_warning"),5800:_T("error","error_invalid"),5801:_T("share","no_such_share"),5901:_T("error","error_subject"),5902:_T("firewall","firewall_vpnpassthrough_restore_failed"),5903:_T("firewall","firewall_vpnpassthrough_specific_platform"),6000:_T("error","error_error_system"),6001:_T("error","error_error_system"),6002:_T("error","error_error_system"),6003:_T("error","error_error_system"),6004:_T("common","loadsetting_fail"),6005:_T("error","error_subject"),6006:_T("error","error_service_start_failed"),6007:_T("error","error_service_stop_failed"),6008:_T("error","error_service_start_failed"),6009:_T("firewall","firewall_save_failed"),6010:_T("common","error_badip"),6011:_T("common","error_badip"),6012:_T("common","error_badip"),6013:_T("share","no_such_share"),6014:_T("cms","cms_no_volumes"),6200:_T("error","error_error_system"),6201:_T("error","error_acl_volume_not_support"),6202:_T("error","error_fat_privilege"),6203:_T("error","error_remote_privilege"),6204:_T("error","error_fs_ro"),6205:_T("error","error_privilege_not_enough"),6206:_T("error","error_no_path"),6207:_T("error","error_no_path"),6208:_T("error","error_testjoin"),6209:_T("error","error_privilege_not_enough"),6210:_T("acl_editor","admin_cannot_set_acl_perm"),6211:_T("acl_editor","error_invalid_user_or_group"),6212:_T("error","error_acl_mp_not_support"),6213:_T("acl_editor","quota_exceeded"),6703:_T("error","error_port_conflict"),6704:_T("error","error_port_conflict"),6705:_T("user","no_such_user"),6706:_T("user","error_nameused"),6708:_T("share","error_volume_not_found"),6709:_T("netbackup","err_create_service_share"),7100:_T("connections","error_disable_admin_name"),8000:_T("router_wireless","wifi_daemon_not_ready"),8001:_T("network","net_daemon_not_ready"),8002:_T("network","usbmodem_daemon_not_ready"),8003:_T("wireless_ap","ap_ssid_limit_alert"),8010:_T("router_topology","get_topology_fail"),8011:_T("network","net_get_fail"),8012:_T("network","net_get_setting_fail"),8013:_T("router_wireless","wifi_setting_get_fail"),8020:_T("router_topology","set_topology_fail"),8021:_T("network","net_set_fail"),8022:_T("network","net_set_setting_fail"),8023:_T("router_wireless","wifi_setting_set_fail"),8030:_T("network","get_redirect_info_fail"),8031:_T("router_common","dhcp_range_conflict_err"),8100:_T("router_wireless","guest_network_get_count_down_fail"),8101:_T("router_wireless","guest_network_set_count_down_fail"),8130:_T("pppoe","pppoe_get_setting_fail"),8131:_T("pppoe","pppoe_set_setting_fail"),8132:_T("pppoe","pppoe_no_interface_available"),8133:_T("pppoe","pppoe_service_start_fail"),8134:_T("pppoe","pppoe_service_stop_fail"),8135:_T("pppoe","pppoe_connection_failed"),8136:_T("pppoe","pppoe_disconnect_fail"),8150:_T("wireless_ap","country_code_get_fail"),8151:_T("wireless_ap","country_code_set_fail"),8152:_T("wireless_ap","country_code_read_list_fail"),8153:_T("wireless_ap","country_code_region_not_support"),8170:_T("routerconf","routerconf_exceed_max_rule"),8175:_T("smartwan","sw_too_many_rules"),8180:_T("routerconf","routerconf_exceed_max_rule"),8190:_T("router_parental","err_device_reach_max"),8200:_T("router_parental","err_domain_name_reach_max"),8230:_T("routerconf","routerconf_exceed_max_reservation"),8231:_T("routerconf","routerconf_exceed_max_reservation_v6")};return a};SYNO.API.AssignErrorStr=function(){SYNO.API.Errors=SYNO.API.GetErrors()};SYNO.API.AssignErrorStr();SYNO.API.Erros=function(){if(Ext.isIE8){return SYNO.API.Errors}var c={},b=function(d){Object.defineProperty(c,d,{get:function(){SYNO.Debug.warn("SYNO.API.Erros is deprecated (typo), please use SYNO.API.Errors instead.");return SYNO.API.Errors[d]},configurable:false})};for(var a in SYNO.API.Errors){if(SYNO.API.Errors.hasOwnProperty(a)){b(a)}}return c}();