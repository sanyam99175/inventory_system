class ProductTypesController < ApplicationController
    def create
        @product_type = current_organization.product_types.new(product_type_params)

        if @product_type.save
            redirect_to product_types_path, notice: t('product_type_created_successfully')
        else
            render :new, status: :unprocessable_entity
        end
    end

    def new
        @product_type = current_organization.product_types.new
    end

    private

    def product_type_params
        params.require(:product_type).permit(:name, :description)
    end
end