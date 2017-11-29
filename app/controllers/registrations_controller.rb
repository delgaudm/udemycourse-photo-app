class RegistrationsController < Device::RegistrationsController
  
  def create
    # we are writing a custom create that handles both the registrations
    # and a sign up payment
    # some code is copied from devise here
    # https://github.com/plataformatec/devise/blob/master/app/controllers/devise/registrations_controller.rb
    build_resource(sign_up_params)
    
    resource.class.transaction do 
      resource.save
      yield resource if block_given?
      if resource.persisted?
        #this we wrote in the tutorial here https://www.udemy.com/the-complete-ruby-on-rails-developer-course/learn/v4/t/lecture/3853696?start=0
        @payment = Payment.new({ email: params["user"]["email"], 
                                 token: params[:payment]['token'],
                                 user_id: resource.id
                               })
        flash[:error] = 'Please check registration errors' unless payment.valid?
        
        begin
          @payment.process_payment
          @payment.save
        rescue Exception => e
          flash[:error] = e.message
          resource.destroy
          puts "Paymnet failed"
          render :new and return
        end
        #this stuff is from here: https://github.com/plataformatec/devise/blob/master/app/controllers/devise/registrations_controller.rb
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource                       
      end
    end
  end
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_santizer.for(:sign_up).push(:payment)
  end
end