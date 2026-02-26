using System;
using System.Data;
using Microsoft.Data.SqlClient;
using HolidayFunORM;

class Program
{
    static void Main(string[] args)
    {
        string connectionString = @"Server=YOUR_SERVER;Database=HolidayFunDB;Trusted_Connection=True;";
        var context = new HolidayFunContext(connectionString);

        Console.WriteLine("=== HolidayFun Phone Reservation ===");

        // 1. Gather customer info
        Console.Write("Customer Name: ");
        string name = Console.ReadLine();

        Console.Write("Address: ");
        string address = Console.ReadLine();

        Console.Write("Phone: ");
        string phone = Console.ReadLine();

        Console.Write("Email: ");
        string email = Console.ReadLine();

        // 2. Gather offer info
        Console.Write("Offer ID: ");
        int offerID = int.Parse(Console.ReadLine());

        Console.Write("Quantity: ");
        int quantity = int.Parse(Console.ReadLine());

        Console.Write("Start Date (YYYY-MM-DD): ");
        DateTime startDate = DateTime.Parse(Console.ReadLine());

        Console.Write("End Date (YYYY-MM-DD): ");
        DateTime endDate = DateTime.Parse(Console.ReadLine());

        // Call stored procedure
        try
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                using (var command = new SqlCommand("usp_makeReservation", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;

                    // Customer info
                    command.Parameters.AddWithValue("@customerName", name);
                    command.Parameters.AddWithValue("@customerAddress", address);
                    command.Parameters.AddWithValue("@customerPhone", phone);
                    command.Parameters.AddWithValue("@customerEmail", email);

                    // Offer list (table-valued parameter)
                    DataTable dtOffers = new DataTable();
                    dtOffers.Columns.Add("offerID", typeof(int));
                    dtOffers.Columns.Add("quantity", typeof(int));
                    dtOffers.Columns.Add("startDate", typeof(DateTime));
                    dtOffers.Columns.Add("endDate", typeof(DateTime));

                    dtOffers.Rows.Add(offerID, quantity, startDate, endDate);

                    SqlParameter tvpParam = command.Parameters.AddWithValue("@OfferList", dtOffers);
                    tvpParam.SqlDbType = SqlDbType.Structured;
                    tvpParam.TypeName = "OfferReservationType";

                    // Output parameter
                    SqlParameter reservationIDParam = new SqlParameter("@ReservationID", SqlDbType.Int);
                    reservationIDParam.Direction = ParameterDirection.Output;
                    command.Parameters.Add(reservationIDParam);

                    // Execute
                    command.ExecuteNonQuery();

                    Console.WriteLine($"Reservation created successfully! Reservation ID: {reservationIDParam.Value}");
                }
            }
        }
        catch (SqlException ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
    }
}
