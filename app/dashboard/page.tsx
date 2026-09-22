"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

type Profile = {
  full_name: string | null;
  role: string;
};

type InventoryItem = {
  product_id: string;
  sku: string;
  product_name: string;
  category_id: string | null;
  hsn_code: string | null;
  unit: string;
  purchase_price: number;
  selling_price: number;
  mrp: number;
  minimum_stock: number;
  current_stock: number;
};

export default function DashboardPage() {
  const router = useRouter();

  const [profile, setProfile] = useState<Profile | null>(null);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [inventoryLoading, setInventoryLoading] = useState(true);

  useEffect(() => {
    async function loadDashboard() {
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) {
        router.replace("/");
        return;
      }

      const { data: profileData, error: profileError } = await supabase
        .from("profiles")
        .select("full_name, role")
        .eq("id", user.id)
        .single();

      if (profileError) {
        console.error("Profile error:", profileError);
      } else {
        setProfile(profileData);
      }

      const { data: inventoryData, error: inventoryError } = await supabase
        .from("current_inventory")
        .select("*")
        .order("product_name");

      if (inventoryError) {
        console.error("Inventory error:", inventoryError);
      } else {
        setInventory(inventoryData ?? []);
      }

      setInventoryLoading(false);
      setLoading(false);
    }

    loadDashboard();
  }, [router]);

  async function handleLogout() {
    await supabase.auth.signOut();
    router.replace("/");
  }

  const totalProducts = inventory.length;

  const totalStock = inventory.reduce(
    (total, item) => total + Number(item.current_stock),
    0
  );

  const lowStockProducts = inventory.filter(
    (item) =>
      Number(item.current_stock) <= Number(item.minimum_stock)
  ).length;

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-gray-100">
        <p className="text-gray-600">Loading dashboard...</p>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="flex flex-col gap-4 bg-white px-6 py-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900">
            Market Inventory
          </h1>

          <p className="text-sm text-gray-500">
            Inventory Management System
          </p>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right">
            <p className="text-sm font-medium text-gray-900">
              {profile?.full_name || "User"}
            </p>

            <p className="text-xs text-gray-500">
              {profile?.role}
            </p>
          </div>

          <button
            onClick={handleLogout}
            className="rounded-lg bg-black px-4 py-2 text-sm font-medium text-white transition hover:bg-gray-800"
          >
            Sign Out
          </button>
        </div>
      </header>

      {/* Dashboard */}
      <section className="p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900">
            Inventory Dashboard
          </h2>

          <p className="mt-1 text-sm text-gray-500">
            Current inventory overview
          </p>
        </div>

        {/* Summary Cards */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-medium text-gray-500">
              Total Products
            </p>

            <p className="mt-2 text-3xl font-bold text-gray-900">
              {totalProducts}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-medium text-gray-500">
              Total Stock
            </p>

            <p className="mt-2 text-3xl font-bold text-gray-900">
              {totalStock}
            </p>

            <p className="mt-1 text-xs text-gray-500">
              Total units across products
            </p>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-medium text-gray-500">
              Low Stock
            </p>

            <p className="mt-2 text-3xl font-bold text-gray-900">
              {lowStockProducts}
            </p>

            <p className="mt-1 text-xs text-gray-500">
              Products at or below minimum stock
            </p>
          </div>
        </div>

        {/* Inventory Table */}
        <div className="mt-6 overflow-hidden rounded-2xl bg-white shadow-sm">
          <div className="border-b border-gray-200 px-6 py-4">
            <h3 className="font-semibold text-gray-900">
              Current Inventory
            </h3>
          </div>

          {inventoryLoading ? (
            <div className="p-6 text-sm text-gray-500">
              Loading inventory...
            </div>
          ) : inventory.length === 0 ? (
            <div className="p-6 text-sm text-gray-500">
              No products found.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[800px]">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                      SKU
                    </th>

                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                      Product
                    </th>

                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                      HSN
                    </th>

                    <th className="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                      Stock
                    </th>

                    <th className="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                      Selling Price
                    </th>

                    <th className="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                      MRP
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-gray-200">
                  {inventory.map((item) => {
                    const isLowStock =
                      Number(item.current_stock) <=
                      Number(item.minimum_stock);

                    return (
                      <tr
                        key={item.product_id}
                        className="hover:bg-gray-50"
                      >
                        <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-600">
                          {item.sku}
                        </td>

                        <td className="px-6 py-4">
                          <div className="font-medium text-gray-900">
                            {item.product_name}
                          </div>

                          <div className="text-xs text-gray-500">
                            {item.unit}
                          </div>
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-600">
                          {item.hsn_code || "-"}
                        </td>

                        <td
                          className={`whitespace-nowrap px-6 py-4 text-right text-sm font-semibold ${
                            isLowStock
                              ? "text-red-600"
                              : "text-gray-900"
                          }`}
                        >
                          {item.current_stock}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-right text-sm text-gray-600">
                          ₹{Number(item.selling_price).toFixed(2)}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-right text-sm text-gray-600">
                          ₹{Number(item.mrp).toFixed(2)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </section>
    </main>
  );
}

