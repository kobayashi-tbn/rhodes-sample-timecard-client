require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'time'
require 'date'

class WorkTimeController < Rho::RhoController
  include BrowserHelper
  
  $choosed = {}
  $saved = nil
  $saved_value = nil

  # GET /WorkTime
  def index
    $choosed.clear
    @worktimes = WorkTime.find(:all)
    render :back => '/app'
  end

  # GET /WorkTime/{1}
  def show
   $choosed.clear
   @worktime = WorkTime.find(@params['id'])
    if @worktime
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /WorkTime/new
  def new
#    $choosed.clear
    @worktime = WorkTime.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /WorkTime/{1}/edit
  def edit
#    $choosed.clear
    @worktime = WorkTime.find(@params['id'])
    if @worktime
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /WorkTime/create
  def create
    @worktime = WorkTime.create(@params['worktime'])
    redirect :action => :index
  end

  # POST /WorkTime/{1}/update
  def update
    @worktime = WorkTime.find(@params['id'])
    @worktime.update_attributes(@params['worktime']) if @worktime
    redirect :action => :index
  end

  # POST /WorkTime/{1}/delete
  def delete
    @worktime = WorkTime.find(@params['id'])
    @worktime.destroy if @worktime
    redirect :action => :index  
  end
  
  ### DateTimeAJ
  def callback_alert
    Alert.show_popup( :message => "Back to home.\n\n Data will be discarded.", :icon => :alert,
    :buttons => ["Ok", "Cancel"], :callback => url_for(:action => :popup_callback) )
  end

  def popup_callback
    id = @params['button_id']
    title = @params['button_title']
    puts "popup_callback: id: '#{id}', title: '#{title}'"
    WebView.navigate '/app' if title.downcase() == 'ok'
  end

  def save
    @work_time = WorkTime.create(@params['worktime'])
    $saved = 1
    redirect :action => :index
#    WebView.navigate '/app/WorkTime/index'
  end

  def popup
    flag = @params['flag']
    field_key = @params['field_key'] # add
    if ['0', '1', '2'].include?(flag)
      #      ttt = $choosed[flag]
      ttt = $choosed[field_key]
      
      if ttt.nil?
        preset_time = Time.new
      else
        preset_time = Time.parse(ttt)
      end

      if flag == '1'
        DateTimePicker.set_change_value_callback url_for(:action => :callback)
        current_value = Time.at(preset_time).strftime('%F')
        #          WebView.execute_js('setFieldValue("date1","'+current_value+'");')
        WebView.execute_js('setFieldValue("'+field_key+'","'+current_value+'");')
        #          $saved_value = $choosed[flag]
        $saved_value = $choosed[field_key]
        if $saved_value.nil?
          $saved_value = ''
        end
      end
      DateTimePicker.choose url_for(:action => :callback), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end

    render :string => '', :back => 'callback:' + url_for(:action => :callback_alert)

  end

  def callback
    if @params['status'] == 'ok'
      $saved = nil
      datetime_vars = Marshal.load(@params['opaque'])
      format = case datetime_vars[:flag]
      when "0" then '%F %T'
      when "1" then '%F'
      when "2" then '%H:%M' #'%T'
      else '%F %T'
      end
      formatted_result = Time.at(@params['result'].to_i).strftime(format)
      #        $choosed[datetime_vars[:flag]] = formatted_result
      $choosed[datetime_vars[:field_key]] = formatted_result
      WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+formatted_result+'");')
    end
    if @params['status'] == 'cancel'
      datetime_vars = Marshal.load(@params['opaque'])
      if datetime_vars[:flag] == '1'
        WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+$saved_value+'");')
      end
    end
    if @params['status'] == 'change'
      datetime_vars = Marshal.load(@params['opaque'])
      if datetime_vars[:flag] == '1'
        formatted_result = Time.at(@params['result'].to_i).strftime('%F')
        #           WebView.execute_js('setFieldValue("date1","'+formatted_result+'");')
        WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+formatted_result+'");')
      end
    end
  end
end
