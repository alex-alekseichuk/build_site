$.namespace("bs", {
	sidebar: function(element) {
		var sidebarid = 0;
		var sidebar_div = jQuery(element);

		var generate_href = function(item) {
			if(item.items) {
				return '/product/view?id=' + item.id;
			}
			return item.url;
		}

		var draw_menu = function() {
			jQuery('#cps-menu').html( $.bs.get_template('cps_dialog_menu', $.bs.current_package()['package']) );
			if (!$.browser.msie)
				jQuery('#cps-menu a[menu_id=print]').parent('li').remove();

			jQuery("ul.drop li")
			.click( function(event) {
					var element = event.target;
					var menu_id = jQuery(element).attr('menu_id');
					var isEndEvent = true;
					switch (menu_id) {
						case 'clear':
							var pkg = $.bs.current_package();
							if (!pkg || !pkg['package'] || !pkg['package'].items.length) {
								return false;
							}
								
							$.bs.confirm("Package Clear", "The package will be cleared. Continue?", function(callback) { 
								package_clear(element, callback); 
							});
							break;
						case 'switch':
							switch_package();
							break;
						case 'save':
							save_package();
							break;
						case 'attach':
							attach_file();
                            break;
						case 'blank':
							blank();
                            break;
						default:
							isEndEvent = false;
					}
					if (isEndEvent) {
						event.stopPropagation();
						event.preventDefault();
					}
			} );
		}

		/**
		 *
		 */
		var parse_data = function(data) {

			var packageData = data['package'];

			jQuery.bs.current_package(data);

			sidebarid = packageData.id;

			jQuery('a[id="current-package-menu-link"]').attr('href', '/folders/edit?file_id='+sidebarid);
			draw_menu();

			var productsData = data.products;
			var treePackage = new Array();
			var inSTR = '';
			var object_type = '';

			if (( data.action != undefined ) && (data.action.result == 'error' )) {
				jQuery.bs.displayErrorMessage((data.action.error?data.action.error:'CPS'), 'CPS');
				return;
			}

			jQuery('input[name="chkItem"]').each(function(i, elem) {
				var jElement = jQuery(elem);
				var type = jElement.attr('class').split(' ')[0];
				if ('file' == type)
					jElement.attr('checked', false);
				var valueCheck = jElement.val();
				var obj = jQuery.grep(packageData.items, function(item) {
						return (valueCheck == item.object_id );
				});

				if ( obj.length != 0 ) {
					jElement.attr('checked',true);
				}
				
				if (valueCheck == packageData.id) {
					jElement.attr('checked', true).attr('disabled', true);
				}
			});

			var processItem = function( item ) {
				var returnStr = '';

				var linkhref = generate_href( item );

				if ( item.items != null ) {
					var subItems = '';

					jQuery.each(item.items, function() {
						subItems += processItem(this);
					} );

					returnStr = jQuery.bs.get_template(
									'cps_product_container', {
									item_id: item.id,
									package_item_id: item.id,
									item_title: item.title,
									short_title: jQuery.bs.get_short_title(item.title, 20),
									object_id: item.object_id,
									linkhref: linkhref,
									sub_items: subItems,
									package_id: packageData.id
								});
				} else {
					if ( item.is_file ) {
						object_type = 'file';
					} else if ( item.is_document )  {
						object_type = 'document';
					} else if ( item.is_product_document )  {
						object_type = 'document';
					}

					var str = '' + object_type + '_id='+ item.object_id ;
					var title = item.product_id ? item.shortname : item.title;
                    var short_title = jQuery.bs.get_short_title(title, 30);
                    
					returnStr = jQuery.bs.get_template(
									'cps_item_container', {
									item_params: str,
									item_title: title,
									short_title: short_title,
									object_type: object_type,
									object_id: item.object_id,
									linkhref: linkhref,
									package_item_id: item.id,
									package_id: packageData.id
								});
				}

				return returnStr;
			}

			jQuery.each(packageData.items, function(i, item) {
				if ( item.product_id != "0" ) {
					obj = jQuery.grep(treePackage, function(aObj) {
						return (aObj.id == item.product_id );
					});

					if ( obj.length == 0 ) {
						obj = jQuery.grep(productsData, function(aObj) {
							return (aObj.id == item.product_id );
						});

						jQuery.extend( obj[0], {items: [] } );

						treePackage.push( obj[0] );
					}

					obj[0].items.push( item );
				} else {
					treePackage.push(item);
				}
			});

			if ( packageData.toc_type ) {
                var now = new Date();
				inSTR += jQuery.bs.get_template( 'cps_toc_link', { 
				        id: packageData.id,
				        type: packageData.toc_type,
				        label: packageData.toc_type_label
				    } );
			}

			jQuery.each( treePackage, function() {
				inSTR += processItem(this);
			});


            // check if toc_preview is already opened
            // we need to keep it in the same mode after refresh
            var toc_preview_opened = false;
            var ico_plus = sidebar_div.find('span.ico_plus')
            if ('undefined' != ico_plus)
                toc_preview_opened = ! $(ico_plus).hasClass('minus');

            // refresh sidebar
			sidebar_div.find('#sidebar_context').html('<ul>'+ inSTR + '</ul>');
			
			var toggle_toc_preview = function() {
				var toc_preview = sidebar_div.find('#toc-preview');

                // if we show toc preview image first time
                // then we need to set src to load it
                var img = sidebar_div.find('#img-toc-preview');
                if (!img.attr('src') || !img.attr('src').match(/toc_thumb/))
                    img.attr('src', '/jstoc/toc_thumb?id=' + packageData.id + '&quirk=' + now.getTime());

                // toggle TOC preview div
                toc_preview.toggleClass('hidden');
				sidebar_div.find('span.ico_plus').toggleClass('minus');
			}
            
            // toggle toc_preview after sidebar refresh
			if (! toc_preview_opened)
			    toggle_toc_preview();

			
			jQuery("li div.ico ul li a").click( function(event) {
				var isEndEvent = true;
				var element = event.target;
				var operation_type = jQuery(element).attr('operation_type');
				switch( operation_type ) {
					case 'delete_product':
						delete_product(element);
						break;
					case 'delete':
						delete_object(element);
						break;
					default:
						isEndEvent = false;
				}
				if (isEndEvent) {
					event.stopPropagation();
					event.preventDefault();
				}
			});

			sidebar_div.find('.ico_plus').click( toggle_toc_preview );

			var strFotter = $.bs.get_template( 'cps_items_summary', {
					count_package_items: packageData.items.length,
					label_item: 'Item' + (packageData.items.length==1?'':'s'),
					count_product_items: productsData.length,
					label_product: 'Product' + (productsData.length==1?'':'s' ),
					id: sidebarid
				});

			jQuery('#sidebar-size').html(	strFotter );

			/*
			sidebar_div.find('li').draggable({
				accept: function( draggable ) {
					return true;
				},
				helper: 'clone'
			});
			*/

			/* commented by ivan - 2008 Dec 24 */
			/*
			sidebar_div.find('#sidebar_context').children('ul').find('x li[class="product"]').children('ul').sortable({
			update: function( ev, ui) {
					var params = {};
					ui.element.children('li[class!="ui-sortable-helper"]').find('a[objectid]').each( function(e1, e2) {
						 params[jQuery(e2).attr('objectid')] = e1+1;
					});
					jQuery.ajax({
							type:		'post',
							url:		'/jspackage/set_items_order',
							data:		params,
							dataType:	'json',
							success:    function(data) {
							},
							error:      function(object, cause) {
								jQuery.bs.displayErrorMessage(object.responseText, 'CPS');
							}
						});
				}
			});
			*/
            var ul_sidebar = sidebar_div.find('#sidebar_context').children('ul');
			ul_sidebar.sortable({
				update: function( ev, ui) {
					var params = {package_id: $.bs.current_package()['package'].id};
					$(ul_sidebar).children('li[class!="ui-sortable-helper"]').find('a[objectid]').each( function(e1, e2) {
						 params[jQuery(e2).attr('objectid')] = e1+1;
					});
					jQuery.ajax({
						type:		'post',
						url:		'/jspackage/set_items_order',
						data:		params,
						dataType:	'json',
						success:    function(data) {
						},
						error:      function(object, cause) {
							jQuery.bs.displayErrorMessage(object.responseText, 'CPS');
						}
					});
				}
			});
			sidebar_div.find('#sidebar_context').children('ul').attr('style', '');

			$(sidebar_div).trigger('changed');
		};

		var save_package = function() {
			$.bs.save_package(false, function(data) {parse_data(data.Result)} );
		}

		var parse_data_form = function(data) {
			parse_data(data.Result);
		}

		var showResponse = function(callback)  {
			jQuery.getJSON(
				'/jspackage/current',
				function(data) {
					parse_data(data.Result);
                    if (typeof callback == 'function')
                        callback();
				}
			);
		}

        
        var blank = function() {
            var ajax_blank = function(){
                $.ajax({
                    url:	'/jspackage/blank',
                    type:	'get',
                    data: {ajax:1},
                    dataType: 'json',
                    success: function(data) {
                        parse_data(data.Result);
                    }
                });
            }

            if ($.bs.should_save_package()) {
                $.bs.package_destructive_dialog(this, ajax_blank);
                return false;
            } else 
                ajax_blank();
        }

        var attach_file = function() {
            var callback_add = function(package_id, id, endCallback) {
                $.ajax({
                    url:  '/jspackage/add_item',
                    type: 'get',
                    data: {package_id: package_id, file_id: id},
                    dataType: 'json',
                    success: function(data) {
                        parse_data(data.Result);
                        if (typeof endCallback == "function")
                            endCallback();
                    }
                });

            }
            var callback_remove = function(package_id, id, endCallback) {
                $.ajax({
                    url:  '/jspackage/remove_item',
                    type: 'get',
                    data: {package_id: package_id, file_id: id},
                    dataType: 'json',
                    success: function(data) {
                        parse_data(data.Result);
                        if (typeof endCallback == "function")
                            endCallback();
                    }
                });

            }
            $.bs.attach_dialog(
                {package_id: sidebarid},
                callback_add,
                callback_remove,
                function(data, callback) {showResponse(callback);}
            );

        };

		var switch_package = function() {
			var closeSaveDlg = function() {};
			var $dlg = jQuery('#switch-dialog');
			if ( $dlg.length == 0 ) {
				jQuery(document.body).append( $.bs.get_template('cps_dialog_switch_wrapper') );
				$dlg = jQuery('#switch-dialog');
                $dlg
                    .bs_dialog( {
                        height: 170
                        ,minWidth: 300
                        ,minHeight: 170
                        ,close: function() {closeSaveDlg();}
                        ,autoOpen: false
                    });
			}

			$dlg.html( $.bs.get_template('progress') );

			$dlg
				.dialog('option', 'buttons', {
					  "Ok": function() {
					  		$dlg.spinner_dialog();
							var id = $dlg.find("#switch-select").attr('value');
							package_switch_to(id, function() {
								$dlg.dialog("close");
								closeSaveDlg();
							});
					  },
					  "Cancel": function() {
					  		closeSaveDlg();
							$dlg.dialog("close");
					  }
					}
				)
                .bs_dialog_open();

			jQuery.getJSON( '/jspackage/list', function(data) {
				var listPackagesData = data.Result.items;
				var optionsStr = '';
				jQuery.each( listPackagesData, function() {
						if ( this.type == 'archive' && this.id != sidebarid) {
							optionsStr += $.bs.get_template('option', this);
						}
				});

				var html = $.bs.get_template('cps_dialog_switch_html', {options: optionsStr});
				if ($.bs.should_save_package()) {
					html = $.bs.get_template('cps_dialog_switch_alert') + html;
				}

				$dlg.html(html);

				$dlg.find("#alert-save-link").click(function() {
					closeSaveDlg = function() {
						$('#savepackage-dialog').dialog('close');
					};
					$.bs.save_package(false, function() {
						$dlg.find(".warning").remove();
					});
					return false;
				});

				$dlg.stretch_dialog('#switch-select', 120);
			} );

		}



		/**
		 *
		 */
		var package_switch_to = function(id, callback) {
			jQuery.getJSON( '/jspackage/make_current?package_id=' + id, function(data) {
				$('input[name="chkItem"].pkg').removeAttr('disabled').removeAttr('checked');
				parse_data(data.Result);
				if (typeof callback == "function")
					callback();
			} );
		}

		/**
		 *
		 */
		var package_clear = function(element, callback) {
			execute( jQuery(element).parent(), 'clear', callback );
		}

		/**
		 *
		 */
		var add_some_object = function(event) {
			var element = event.target;
			add_remove_element( element );
		}

		var add_remove_element = function(element) {
			var str = '';
			var jElement = jQuery( element );
			if ( jElement.length == 0 ) {
				alert('see errror');
				return;
			}

            var object_type = jElement.attr('class').split(' ')[0];

            var process = function() {
                if ( jElement.attr('checked') ) {
                    str = 'add_item';
                    if ('pkg' == object_type)
                    	jElement.attr('disabled', 'disabled');
                } else {
                    str = 'remove_item';
                }

                str += '?' + object_type + '_id=' + jElement.val();
				str += '&package_id=' + $.bs.current_package()['package'].id;

                jQuery(element).addClass('novisible');
                jQuery(element).parent().addClass('wait');

                jQuery.getJSON( '/jspackage/'+str, function(data) {
                    jQuery(element).parent().removeClass('wait');
                    jQuery(element).removeClass('novisible');
                    parse_data(data.Result);
                } );
            }

            // is it package_adding?
            if ( jElement.attr('checked') && 'pkg' == object_type ) {
                jElement.attr('checked', false);
                $.bs.add_package_dialog(jElement.val(), currentPackageJSON['package'].id, function(){jElement.attr('checked', 'checked');process();});
            } else {
                process();
            }
		}

		/**
		 *
		 */
		var delete_product = function(element) {
			var str = '';
			str += 'product_id=' + jQuery(element).attr('object_id');

			execute( jQuery(element).parents('div.ico'), 'remove_product?'+str );
		}

		/**
		 *
		 */
		var delete_object = function(element) {
			var str = '';
			str += jQuery(element).attr('object_type').split(' ')[0] + '_id=' + jQuery(element).attr('object_id');

			execute( jQuery(element).parents('div.ico'), 'remove_item?'+str );
		}

		var execute = function( element, url, callback) {
			sendAjax(  element, '/jspackage/' + url, callback);
		}


		/**
		 *
		 */
		var get_content_data = function() {
			if (typeof currentPackageJSON != "undefined")
				parse_data(currentPackageJSON);
		};

		/**
		 *
		 */
		var sendAjax = function( waitElement, url, callback) {
			var jqueryWaitElement = jQuery(waitElement);
			jqueryWaitElement.addClass('wait');

			jQuery.ajax({
				type:		'get',
				url: 		url,
				data: 		{package_id: $.bs.current_package()['package'].id},
				dataType: 	'json',
				success: 	function(data) {
					jqueryWaitElement.removeClass('wait');
					parse_data_form(data);
					if ("function" == typeof callback)
						callback();
				},
				error:		function(object, cause) {
					jqueryWaitElement.removeClass('wait');
					jQuery.bs.displayErrorMessage(object.responseText, 'CPS');
				}
			});
		}

		/**
		 *
		 */
		sidebar_div.html( $.bs.get_template('cps_wrapper') );


		jQuery('#sidebar_toggle').click( function(event) {
			jQuery('#sidebar_context').slideToggle("normal");
			return false;
		});

		get_content_data();


		if ( jQuery.browser.msie && jQuery.browser.version == '6.0'  ) {
			$('input[name="chkItem"]').parents('tr').find('a[target="_blank"]').draggable({
				helper: 'clone'
			});
			$('input[name="chkItem"]').parents('tr').find('a.document').draggable({
				helper: 'clone'
			});
		} else {
			jQuery('input[name="chkItem"]').parents('tr').draggable({
				cursorAt: {
						top: true,
						left: true
				},
				helper: function() {
							var content;
							if(jQuery("td a.document",this).length) {
								content = jQuery(this).find("td:has(a.document)").html();
							} else {
								content = jQuery("td:first",this).html() + '&nbsp;' + jQuery(this).find('td:first + td').html();
							}
							return jQuery.bs.get_template( 'cps_dnd_container', {
										content: content
								});
						}
			});
		}

		jQuery(element).bind('update', function() {
			showResponse();
		});

		if ( jQuery.browser.msie && jQuery.browser.version == '6.0' ) {
			sidebar_div.droppable({
				accept:			'a[target="_blank"]',
				activeClass:	'droppable-active',
				hoverClass:		'droppable-hover',
				drop:			function( ev, ui ) {
									var element = ui.draggable.parents('tr').find('input[name="chkItem"]')
									$(element).attr('checked', true);
									add_remove_element( element );


								}
			});
			sidebar_div.droppable({
				accept:			'a.document',
				activeClass:	'droppable-active',
				hoverClass:		'droppable-hover',
				drop:			function( ev, ui ) {
									var element = ui.draggable.parents('tr').find('input[name="chkItem"]')
									$(element).attr('checked', true);
									add_remove_element( element );


								}
			});
		} else {
			sidebar_div.droppable({
				accept:			'tr',
				activeClass:	'droppable-active',
				hoverClass:		'droppable-hover',
				drop:			function( ev, ui ) {
									var element = jQuery(ui.draggable).find('input[name="chkItem"]');
									if ( element != null ) {
										jQuery(element).attr('checked', true);
										add_remove_element( element );
									}
								}
			});
		}

		jQuery('input[name="chkItem"]').click( add_some_object );

	}
});

(function($) {
	$(document).ready( function() {
		if ("undefined" != typeof currentPackageJSON)
        {
			$('#placement_sidebar').bs.sidebar();
        }
	});
})(jQuery);
