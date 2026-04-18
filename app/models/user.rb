class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { worker: 0, owner: 1 }

  has_many :requests, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :histories, dependent: :nullify
  has_many :stock_requests, dependent: :nullify
end
