Sys.Application.add_init(function ()
{
    (function ()
    {

        var $,
     $t,
     $DateTime,
     timePerMinute = 60000,
     timePerHour = timePerMinute * 60,
        timePerDay = timePerHour * 24,
        maxDate = new Date("9000/01/01"),
     toolTipZIndex = 10000,
     resourceControlSuffix = "_ResourceValue";

        window.SchedulerAdvancedTemplate = function (schedulerElement, formElement, isModal)
        {
            $ = window.$telerik.$;
            $t = window.Telerik.Web.UI;
            $DateTime = $t.Scheduler.DateTime;

            this._scheduler = window.$find(schedulerElement.id);
            this._schedulerElement = schedulerElement;
            this._formElement = formElement;
            this._schedulerElementId = this._schedulerElement.id;
            this._isModal = isModal;
            this._eventNamespace = schedulerElement.id;

            // We need to obtain the ID of the naming container that
            // contains the advanced template. We can find it from
            // the ID of a known element hosted in the form,
            // such as BasicControlsPanel.
            var basicControlsPanel = $("div.rsAdvBasicControls", formElement);
            if (basicControlsPanel.length == 0)
                return;

            var basicControlsPanelId = basicControlsPanel[0].id;
            this._templateId = basicControlsPanelId.substring(0, basicControlsPanelId.lastIndexOf("_"));
        };

        window.SchedulerAdvancedTemplate._adjustHeight = function (schedulerElement)
        {
            // Stretches the rsAdvOptions div to the available height.
            var advancedEditDiv = $("div.rsAdvancedEdit:visible", schedulerElement);
            var contentWrapper = $(".rsAdvContentWrapper", advancedEditDiv);
            var excludedBorders = advancedEditDiv.outerHeight() - advancedEditDiv.height();
            excludedBorders += contentWrapper.outerHeight() - contentWrapper.height();

            var titleHeight = $("div.rsAdvTitle:visible", schedulerElement).outerHeight({ margin: true });

            var buttonsDiv = $("div.rsAdvancedSubmitArea", advancedEditDiv);
            var buttonsHeight = buttonsDiv.outerHeight({ margin: true });

            var targetHeight = $(schedulerElement).height() - titleHeight - buttonsHeight - excludedBorders;
            $(".rsAdvOptionsScroll", advancedEditDiv).height(targetHeight + "px");

            // IE fix
            if (buttonsDiv[0])
                buttonsDiv[0].style.cssText = buttonsDiv[0].style.cssText;
        };

        window.SchedulerAdvancedTemplate.prototype =
{
    initialize: function ()
    {
        var scheduler = this._scheduler;
        scheduler.add_disposing(Function.createDelegate(this, this.dispose));

        // Enable the buttons in the advanced form
        $("div.rsAdvancedSubmitArea a", this._formElement).attr("onclick", "");

        if (scheduler.get_overflowBehavior() == 1 && !this._isModal)
            window.SchedulerAdvancedTemplate._adjustHeight(this._schedulerElement);

        this._initializePickers();
        this._initializeAdvancedFormValidators();
        this._initializeAllDayCheckbox();

        var recurrenceSupport = this._getRecurrenceEditor() != null;
        if (recurrenceSupport)
        {
            this._initializeResetExceptions();
        }

        if (window.$telerik.isIE)
        {
            var textarea = this._getSubjectTextBox().get_element();
            textarea.style.cssText = textarea.style.cssText;
        }

        // Exclude the spin button arrows from the tab order
        $('.riUp, .riDown', this._formElement).attr("tabindex", "-1");
    },

    dispose: function ()
    {
        if (!this._formElement)
            return;

        $("*", this._formElement).unbind();
        $(document).unbind("." + this._eventNamespace);

        this._pickers = null;
        this._scheduler = null;
        this._schedulerElement = null;
        this._formElement = null;
    },

    // The populate function is needed only when using Web Service data binding.
    populate: function (apt, isInsert)
    {
        if (!this._clientMode)
            this._initializeClientMode();

        this._appointment = apt;
        this._isInsert = isInsert;

        var isAllDay =
            $DateTime.getTimeOfDay(apt.get_start()) == 0 &&
            $DateTime.getTimeOfDay(apt.get_end()) == 0;

        var aptEndDate = $DateTime.getDate(apt.get_end());
        if (isAllDay)
            aptEndDate = $DateTime.add(aptEndDate, -timePerDay);

        this._getSubjectTextBox().set_value(apt.get_subject());

        var descrTextBox = this._getDescriptionTextBox();
        if (descrTextBox)
            descrTextBox.set_value(apt.get_description());

        this._pickers.startDate.set_selectedDate($DateTime.getDate(apt.get_start()));
        this._pickers.startTime.set_selectedDate(apt.get_start());
        this._pickers.endDate.set_selectedDate(aptEndDate);
        this._pickers.endTime.set_selectedDate(apt.get_end());

        this._populateResources();
        this._populateAttributes();

        this._initalizeResetExceptionsClientMode();

        var allDayCheckBox = $("#" + this._templateId + "_AllDayEvent");
        if (isAllDay != allDayCheckBox[0].checked)
        {
            allDayCheckBox[0].checked = isAllDay;
            this._onAllDayCheckBoxClick(isAllDay, false);
        }

        this._populateRecurrence();
        this._populateReminder();
        this._populateTimeZones();
    },

    _initializeClientMode: function ()
    {
        this._clientMode = true;
        var template = this;

        $("a.rsAdvEditSave", this._formElement)
            .click(function (e)
            {
                template._saveClicked();
                window.$telerik.cancelRawEvent(e);
            })
            .attr("href", "#");

        $("a.rsAdvEditCancel, a.rsAdvEditClose", this._formElement)
            .click(function (e)
            {
                template._cancelClicked();
                window.$telerik.cancelRawEvent(e);
            })
            .attr("href", "#");
    },

    _initalizeResetExceptionsClientMode: function ()
    {
        var resetExceptions = $("span.rsAdvResetExceptions > a", this._formElement);
        var hasExceptions = this._appointment.get_recurrenceRule().indexOf("EXDATE") != -1;

        resetExceptions.unbind();

        if (hasExceptions)
        {
            var template = this;
            var localization = this._scheduler.get_localization();
            resetExceptions
                .attr("href", "#")
                .text(localization.AdvancedReset)
                .click(function ()
                {
                    // Display confirmation dialog
                    template._getRemoveExceptionsDialog()
                        .set_onActionConfirm(function ()
                        {
                            // The user has confirmed - proceed
                            template._scheduler.removeRecurrenceExceptions(template._appointment);
                            resetExceptions.text(localization.AdvancedDone);
                        })
                        .show();

                    return false;
                });
        }
        else
        {
            resetExceptions.text("");
        }
    },

    // Click handler for the "Save" button
    _saveClicked: function ()
    {
        if (typeof (window.Page_ClientValidate) != "undefined")
        {
            var validationGroup = this._scheduler.get_validationGroup() + (this._isInsert ? "Insert" : "Edit");
            if (!window.Page_ClientValidate(validationGroup))
                return;
        }

        var apt = this._appointment;
        apt.set_subject(this._getSubjectTextBox().get_value());

        var descrTextBox = this._getDescriptionTextBox();
        if (descrTextBox)
            apt.set_description(descrTextBox.get_value());

        var isAllDay = window.$get(this._templateId + "_AllDayEvent").checked;

        var startDate = this._pickers.startDate.get_selectedDate();
        var startTime = $DateTime.getTimeOfDay(this._pickers.startTime.get_selectedDate());
        apt.set_start($DateTime.add(startDate, isAllDay ? 0 : startTime));

        var endDate = this._pickers.endDate.get_selectedDate();
        var endTime = $DateTime.getTimeOfDay(this._pickers.endTime.get_selectedDate());
        apt.set_end($DateTime.add(endDate, isAllDay ? timePerDay : endTime));

        this._saveResources(apt);
        this._saveAttributes(apt);

        this._saveRecurrenceRule(apt);
        this._saveReminder(apt);
        this._saveTimeZone(apt);

        if (this._isInsert)
            this._scheduler.insertAppointment(apt);
        else
            this._scheduler.updateAppointment(apt);

        this._scheduler.hideAdvancedForm();
    },

    _cancelClicked: function ()
    {
        this._scheduler.hideAdvancedForm();
    },

    _saveResources: function (apt)
    {
        var template = this;
        var schedulerResources = this._scheduler.get_resources();

        this._scheduler.get_resourceTypes().forEach(function (resourceType)
        {
            var resourceTypeName = resourceType.get_name();
            var baseName = template._templateId + "_Res" + resourceTypeName + resourceControlSuffix;
            var resourcesOfThisType = schedulerResources.getResourcesByType(resourceTypeName);

            if (resourceType.get_allowMultipleValues())
            {
                var checkBoxes = $(String.format("input[id*='{0}']", baseName), this._formElement);

                if (checkBoxes.length > 0)
                    apt.get_resources().removeResourcesByType(resourceTypeName);

                for (var i = 0; i < checkBoxes.length; i++)
                {
                    if (checkBoxes[i].checked && resourcesOfThisType.get_count() >= i)
                        apt.get_resources().add(resourcesOfThisType.getResource(i));
                }
            }
            else
            {
                var dropDown = window.$find(baseName);
                if (!dropDown)
                    return;

                apt.get_resources().removeResourcesByType(resourceTypeName);

                if (dropDown.get_selectedIndex() == 0)
                    return;

                var selectedValue = dropDown.get_selectedItem().get_value();
                var newResource = schedulerResources.findAll(function (res)
                {
                    return res.get_type() == resourceTypeName &&
                           res._getInternalKey() == selectedValue;
                }).getResource(0) || null;

                if (newResource)
                    apt.get_resources().add(newResource);
            }
        });
    },

    _saveAttributes: function (apt)
    {
        var template = this;
        var aptAttributes = apt.get_attributes();
        $.each(this._scheduler.get_customAttributeNames(), function ()
        {
            var attrName = this.toString();
            var textBox = window.$find(template._templateId + "_Attr" + attrName);
            if (!textBox)
                return;

            aptAttributes.removeAttribute(attrName);
            aptAttributes.setAttribute(attrName, textBox.get_value());
        });
    },

    _getResourceIndex: function (res)
    {
        var resources = this._scheduler.get_resources().getResourcesByType(res.get_type());
        var index, length;

        for (index = 0, length = resources.get_count(); index < length; index++)
        {
            var filteredRes = resources.getResource(index);
            if (filteredRes.get_type() == res.get_type() && filteredRes.get_key() == res.get_key())
                return index;
        }

        return -1;
    },

    _populateResources: function ()
    {
        var template = this;
        var resourceTypes = this._scheduler.get_resourceTypes();

        resourceTypes.forEach(function (resType)
        {
            var baseName = template._templateId + "_Res" + resType.get_name() + resourceControlSuffix;

            if (resType.get_allowMultipleValues())
            {
                // Clear the resource checkboxes
                $(String.format("input[id*='{0}']", baseName), this._formElement)
                    .each(function ()
                    {
                        this.checked = false;
                    });
            }
            else
            {
                var dropDown = window.$find(baseName);
                if (dropDown)
                    dropDown.get_items().getItem(0).select();
            }
        });

        this._appointment.get_resources().forEach(function (res)
        {
            var baseName = template._templateId + "_Res" + res.get_type() + resourceControlSuffix;
            var resType = resourceTypes.getResourceTypeByName(res.get_type());
            if (resType && resType.get_allowMultipleValues())
            {
                var resIndex = template._getResourceIndex(res);
                var checkBox = window.$get(baseName + "_" + resIndex);

                if (checkBox)
                    checkBox.checked = true;
            }
            else
            {
                var dropDown = window.$get(baseName);
                if (dropDown)
                    template._selectDropDownValue(dropDown, res._getInternalKey());
            }
        });
    },

    _populateAttributes: function ()
    {
        var template = this;
        this._appointment.get_attributes().forEach(function (attr, attrValue)
        {
            var textBox = window.$find(template._templateId + "_Attr" + attr);
            if (!textBox)
                return;

            textBox.set_value(attrValue);
        });
    },

    _saveRecurrenceRule: function (apt)
    {
        var editor = this._getRecurrenceEditor();
        if (!editor) return;

        editor.set_startDate(this._scheduler.displayToUtc(apt.get_start()));
        editor.set_endDate(this._scheduler.displayToUtc(apt.get_end()));
        editor.set_firstDayOfWeek(this._scheduler.get_firstDayOfWeek());

        var rrule = editor.get_recurrenceRule();
        if (!rrule)
        {
            apt.set_recurrenceRule("");
            return;
        }

        // Restore the original recurrence exceptions if the
        // appointment was already recurring.
        var originalRRule = $t.RecurrenceRule.parse(apt.get_recurrenceRule());
        if (originalRRule)
            Array.addRange(rrule.get_exceptions(), originalRRule.get_exceptions());

        var range = rrule.get_range();
        if (range.get_recursUntil().getTime() != maxDate.getTime())
        {
            var recursUntil = this._scheduler.displayToUtc(range.get_recursUntil());

            if (!this._getElement("AllDayEvent").checked)
                recursUntil = $DateTime.add(recursUntil, timePerDay);

            range.set_recursUntil(recursUntil);
        }

        apt.set_recurrenceRule(rrule.toString());
    },

    _saveTimeZone: function (apt)
    {
        var timeZonesDropDown = this._getTimeZonesDropDown();
        if (!timeZonesDropDown) return;

        var selectedValue = timeZonesDropDown.get_value();
        if (selectedValue != this._scheduler._timeZoneID)
            apt.set_timeZoneID(selectedValue);

    },

    _saveReminder: function (apt)
    {
        var reminderDropDown = this._getReminderDropDown();
        if (!reminderDropDown) return;

        var selectedValue = reminderDropDown.get_value();
        var aptReminders = apt.get_reminders();
        if (selectedValue)
        {
            var reminderMinutes = parseInt(selectedValue, 10);
            if (aptReminders.get_count() > 0)
            {
                aptReminders.getReminder(0).set_trigger(reminderMinutes);
            }
            else
            {
                var reminder = new $t.Reminder();
                reminder.set_trigger(reminderMinutes);
                aptReminders.add(reminder);
            }
        }
        else
        {
            if (aptReminders.get_count() > 0)
                aptReminders.removeAt(0);
        }
    },

    _populateRecurrence: function ()
    {
        var editor = this._getRecurrenceEditor();
        if (!editor) return;

        var rrule = $t.RecurrenceRule.parse(this._appointment.get_recurrenceRule());
        if (rrule)
        {
            var range = rrule.get_range();
            var recursUntil = range.get_recursUntil().getTime();
            if (recursUntil != maxDate.getTime())
            {
                recursUntil = this._scheduler.utcToDisplay(range.get_recursUntil());

                if (!this._getElement("AllDayEvent").checked)
                    recursUntil = $DateTime.add(recursUntil, -timePerDay);

                range.set_recursUntil(recursUntil);
            }
        }
        else
        {
            editor.set_startDate(this._appointment.get_start());
            editor.set_endDate(this._appointment.get_end());
        }

        editor.set_recurrenceRule(rrule);
    },

    _populateTimeZones: function ()
    {
        var timeZonesDropDown = this._getTimeZonesDropDown();
        if (!timeZonesDropDown) return;

        var timeZone = this._appointment.get_timeZoneID();
        if (!timeZone)
            this._selectDropDownValue(timeZonesDropDown.get_element(), this._scheduler._timeZoneId);
        else
            this._selectDropDownValue(timeZonesDropDown.get_element(), timeZone);
    },

    _populateReminder: function ()
    {
        var reminderDropDown = this._getReminderDropDown();
        if (!reminderDropDown) return;

        var reminder = this._appointment.get_reminders().getReminder(0);
        if (!reminder)
            this._selectDropDownValue(reminderDropDown.get_element(), "");
        else
            this._selectDropDownValue(reminderDropDown.get_element(), reminder.get_trigger());
    },

    _selectDropDownValue: function (dropDown, value)
    {
        var comboBox = window.$find(dropDown.id);
        if (comboBox && $t.RadComboBox.isInstanceOfType(comboBox))
        {
            comboBox.get_items().forEach(function (item)
            {
                if (item.get_value() == value)
                    item.select();
            });
        }
        else
        {
            $.each(dropDown.options, function ()
            {
                if (this.value == value)
                {
                    this.selected = true;
                    return false;
                }
            });
        }
    },

    _getSubjectTextBox: function ()
    {
        return window.$find(this._templateId + "_SubjectText");
    },

    _getDescriptionTextBox: function ()
    {
        return window.$find(this._templateId + "_DescriptionText");
    },

    _getRecurrenceEditor: function ()
    {
        return window.$find(this._templateId + "_AppointmentRecurrenceEditor");
    },

    _getReminderDropDown: function ()
    {
        return this._getControl("ReminderDropDown");
    },

    _getTimeZonesDropDown: function ()
    {
        return this._getControl("TimeZonesDropDown");
    },

    _getElement: function (id)
    {
        return window.$get(this._templateId + "_" + id);
    },

    _getControl: function (id)
    {
        return window.$find(this._templateId + "_" + id);
    },

    _initializePickers: function ()
    {
        // Show picker pop-ups when the inputs are focused

        var showPopupDelegate = Function.createDelegate(this, this._showPopup);

        var templateId = this._templateId;
        this._pickers =
          {
              "startDate": window.$find(templateId + "_StartDate"),
              "endDate": window.$find(templateId + "_EndDate"),
              "startTime": window.$find(templateId + "_StartTime"),
              "endTime": window.$find(templateId + "_EndTime")
          };

        $.each(
               this._pickers,
               function ()
               {
                   if (this && this.get_dateInput)
                       this.get_dateInput().add_focus(showPopupDelegate);
               });


        var pickerControls = [
                         window.$get(this._pickers.startDate.get_element().id + "_wrapper"),
                         window.$get(this._pickers.startTime.get_element().id + "_wrapper"),
                         window.$get(this._pickers.startTime.get_element().id + "_timeView_wrapper"),
                         window.$get(this._pickers.endDate.get_element().id + "_wrapper"),
                         window.$get(this._pickers.endTime.get_element().id + "_wrapper"),
                         window.$get(this._pickers.endTime.get_element().id + "_timeView_wrapper"),
                         window.$get(this._templateId + "_SharedCalendar")
                    ];

        // Hide the pickers when the focus moves to another element in the template
        var advancedTemplate = this;
        var eventName = "focusin";

        $(this._formElement).bind(eventName,
               function (e)
               {
                   var inPickerControls = false;
                   for (var i = 0, len = pickerControls.length; i < len; i++)
                   {
                       var control = pickerControls[i];
                       if (window.$telerik.isDescendantOrSelf(control, e.target))
                       {
                           inPickerControls = true;
                           break;
                       }
                   }

                   if (!inPickerControls)
                       advancedTemplate._hidePickerPopups();
               });

        // Custom jQuery event fired when the pop-up advanced
        // form has been moved.
        $(this._formElement).bind("formMoving", function ()
        {
            advancedTemplate._hidePickerPopups();
        });

        if (this._isModal)
            $(document).bind("scroll." + this._eventNamespace, function ()
            {
                advancedTemplate._hidePickerPopups();
            });
    },

    _initializeAdvancedFormValidators: function ()
    {
        var toolTip = this._createValidatorToolTip();

        if (typeof (window.Page_Validators) == "undefined")
            return;

        for (var validatorIndex in window.Page_Validators)
        {
            var validator = window.Page_Validators[validatorIndex];
            if (this._validatorIsInTemplate(validator))
            {
                var control = $("#" + validator.controltovalidate);
                if (control.length == 0)
                    break;

                if (control.parent().is(".rsAdvDatePicker") ||
                         control.parent().is(".rsAdvTimePicker"))
                {
                    $("#" + validator.controltovalidate + "_dateInput")
                              .bind("focus", { "toolTip": toolTip }, this._showToolTip)
                              .bind("blur", { "toolTip": toolTip }, this._hideToolTip)
                              [0].errorMessage = validator.errormessage;
                }
                else
                {
                    control.addClass("rsValidatedInput");
                }

                control[0].errorMessage = validator.errormessage;
                this._updateValidator(validator, control);
            }
        }

        var advancedTemplate = this;
        var originalValidatorUpdateDisplay = ValidatorUpdateDisplay;

        ValidatorUpdateDisplay = function (validator)
        {
            if (advancedTemplate._validatorIsInTemplate(validator) && validator.controltovalidate)
            {
                advancedTemplate._updateValidator(validator);
            }
            else
            {
                originalValidatorUpdateDisplay(validator);
            }
        };

        $(".rsValidatedInput", this._formElement)
               .bind("focus", { "toolTip": toolTip }, this._showToolTip)
               .bind("blur", { "toolTip": toolTip }, this._hideToolTip);
    },

    _initializeAllDayCheckbox: function ()
    {
        var allDayCheckbox = $("#" + this._templateId + "_AllDayEvent");
        var controlList = $(allDayCheckbox[0].parentNode.parentNode.parentNode);
        var timePickers = controlList.find('.rsAdvTimePicker');

        // RadDateTimePicker-display-hackedy-hack
        if (window.$telerik.isIE6 || window.$telerik.isIE7)
        {
            $('.rsAdvTimePicker, .rsAdvDatePicker', this._formElement).css(
               {
                   display: "inline",
                   zoom: 1,
                   width: ""
               });
        }
        else
        {
            $('.rsAdvTimePicker, .rsAdvDatePicker', this._formElement).css(
               {
                   display: "inline-block",
                   width: ""
               });
        }

        var timePickersWidth = $("#" + this._templateId + "_StartTime_dateInput").outerWidth();

        timePickers.width(timePickersWidth);

        var initialPickersWidth = $(".rsTimePick", this._formElement).eq(0).outerWidth();
        var allDayPickersWidth = initialPickersWidth - timePickersWidth;

        var startTimeValidator = window.$get(this._templateId + "_StartTimeValidator");
        var endTimeValidator = window.$get(this._templateId + "_StartTimeValidator");

        var advancedTemplate = this;

        // IE fix - the hidden input pushes down the other TimePicker elements during animation
        controlList.find('.rsAdvTimePicker > input').css("display", "none");

        var clickHandler = function (allDay, animate)
        {
            var showTimePickers = function ()
            {
                if (window.$telerik.isSafari || window.$telerik.isOpera)
                    timePickers.css("display", "inline-block");
                else
                    timePickers.show();
            };

            if (!allDay)
                showTimePickers();

            controlList.find('.rsTimePick').each(function ()
            {
                if (animate)
                {
                    $(this).stop();

                    if (allDay)
                        $(this).animate({ width: allDayPickersWidth }, "fast",
                                   "linear", function () { timePickers.hide(); });
                    else
                        $(this).animate({ width: initialPickersWidth }, "fast");
                }
                else
                {
                    if (allDay)
                    {
                        timePickers.hide();
                        $(this).width(allDayPickersWidth);
                    }
                    else
                    {
                        $(this).width(initialPickersWidth);
                    }
                }
            });

            if (typeof (window.ValidatorEnable) != "undefined")
            {
                window.ValidatorEnable(startTimeValidator, !allDay);
                window.ValidatorEnable(endTimeValidator, !allDay);
            }

            var startTimePicker = advancedTemplate._pickers.startTime;
            startTimePicker.set_enabled(!allDay);

            var endTimePicker = advancedTemplate._pickers.endTime;
            endTimePicker.set_enabled(!allDay);
        };

        this._onAllDayCheckBoxClick = clickHandler;

        clickHandler(allDayCheckbox[0].checked, false);
        allDayCheckbox.click(function () { clickHandler(this.checked, true); });
    },

    _initializeResetExceptions: function ()
    {
        var resetExceptions = $("#" + this._templateId + "_ResetExceptions");
        if (resetExceptions.length == 0)
            return;

        var scheduler = this._scheduler;
        var template = this;
        var localization = scheduler.get_localization();
        var doneMessage = localization.AdvancedDone;
        if (resetExceptions[0].innerHTML.indexOf(doneMessage) > -1)
        {
            // Hide "Done" after 2 seconds
            resetExceptions.click(function () { return false; });
            window.setTimeout(function () { resetExceptions.fadeOut("slow"); }, 2000);
        }
        else
        {
            resetExceptions.click(
                function ()
                {
                    // Display confirmation dialog
                    var dialog = template._getRemoveExceptionsDialog();
                    dialog.set_onActionConfirm(function ()
                    {
                        // The user has confirmed - proceed with postback
                        resetExceptions[0].innerHTML = localization.AdvancedWorking;
                        window.location.href = resetExceptions[0].href;

                        dialog.dispose();
                    })
                        .show();

                    return false;
                });
        }
    },

    _getRemoveExceptionsDialog: function ()
    {
        var localization = this._scheduler.get_localization();
        return window.$telerik.$.modal(this._formElement)
            .initialize()
            .set_content({
                title: localization.ConfirmResetExceptionsTitle,
                content: localization.ConfirmResetExceptionsText,
                ok: localization.ConfirmOK,
                cancel: localization.ConfirmCancel
            });
    },

    _updateValidator: function (validator)
    {
        var control = $("#" + validator.controltovalidate);

        if (control.is(".rsValidatedInput"))
            control = control.parent();

        if (!validator.isvalid)
            control.addClass("rsInvalid");
        else
            control.removeClass("rsInvalid");
    },

    _validatorIsInTemplate: function (validator)
    {
        return $(validator).parents().is("#" + this._schedulerElementId);
    },

    _createValidatorToolTip: function ()
    {
        return $('<div></div>').hide().appendTo($('.rsAdvancedEdit:visible', window.$get(this._schedulerElementId)));
    },

    _showToolTip: function (e)
    {
        var toolTip = e.data.toolTip;
        var control = $(this);
        var isTextArea = false;
        var controlParent = control.parent();

        if (control.is("textarea"))
        {
            isTextArea = true;
            control = controlParent;
        }

        var isInvalid = control.is(".rsInvalid");
        // Date and time pickers are validated against a hidden input located one level up in the DOM
        isInvalid = isInvalid || controlParent.parent().children().is(".rsInvalid");

        if (isInvalid)
        {
            toolTip
                    .css("visibility", "hidden")
                    .text(this.errorMessage)
                    .addClass("rsValidatorTooltip");

            var positionOrigin = control;
            if (controlParent.is(".riCell"))
                positionOrigin = controlParent;

            var pos = positionOrigin.position();
            var toolTipLeft = pos.left + "px";

            if (isTextArea)
            {
                toolTipLeft = (pos.left + positionOrigin.outerWidth() - toolTip.outerWidth()) + "px";
            }

            var toolTipTop = (pos.top - toolTip.outerHeight()) + "px";
            toolTip
                    .css({
                        top: toolTipTop,
                        left: toolTipLeft,
                        zIndex: toolTipZIndex,
                        visibility: "visible"
                    })
                    .fadeIn("fast");
        }
    },

    _hideToolTip: function (e)
    {
        var toolTip = e.data.toolTip;
        toolTip.hide();
    },

    _hidePickerPopups: function ()
    {
        if (!this._pickers)
            return;

        for (var pickerId in this._pickers)
        {
            var picker = this._pickers[pickerId];

            if (!picker)
                continue;

            if (picker.hideTimePopup)
                picker.hideTimePopup();
            else
                picker.hidePopup();
        }
    },

    _showPopup: function (sender)
    {
        this._hidePickerPopups();

        if (sender.Owner.showTimePopup)
            sender.Owner.showTimePopup();
        else
            sender.Owner.showPopup();
    }
};
    })();
});