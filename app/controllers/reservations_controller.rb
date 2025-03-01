class ReservationsController < ApplicationController
  before_action :authenticate_user!  # ログイン必須に

  def new
    if params[:date].blank? || params[:sheet_id].blank?
      redirect_to movie_reservation_path(params[:movie_id], schedule_id: params[:schedule_id], date: params[:date]), alert: "座席を選択してください。" and return
    end

    @reservation = Reservation.new
    @movie = Movie.find(params[:movie_id])
    @schedule = Schedule.find(params[:schedule_id])
    
    # スクリーンに紐づく座席を取得
    @sheets = Sheet.where(screen_id: @schedule.screen_id)
    @sheet = @sheets.find_by(id: params[:sheet_id])

    # 予約済みチェック
    if Reservation.exists?(schedule_id: @schedule.id, sheet_id: @sheet.id, date: params[:date])
      redirect_to movie_reservation_path(@movie, schedule_id: @schedule.id, date: params[:date]), alert: "その座席はすでに予約済みです。" and return
    end
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)
    # ユーザー情報を自動設定
    @reservation.name = current_user.name
    @reservation.email = current_user.email

    if Reservation.exists?(schedule_id: @reservation.schedule_id, sheet_id: @reservation.sheet_id, date: @reservation.date)
      redirect_to movie_reservation_path(@reservation.schedule.movie, schedule_id: @reservation.schedule_id, date: @reservation.date), alert: "その座席はすでに予約済みです。" and return
    end

    if @reservation.save
      redirect_to movie_path(@reservation.schedule.movie), notice: "予約が完了しました。"
    else
      redirect_to movie_reservation_path(@reservation.schedule.movie, schedule_id: @reservation.schedule_id, date: @reservation.date), alert: "予約に失敗しました。"
    end
  end

  private

  def reservation_params
    # name, emailはユーザー情報から自動設定するため、パラメータからは除外
    params.require(:reservation).permit(:date, :schedule_id, :sheet_id)
  end
end