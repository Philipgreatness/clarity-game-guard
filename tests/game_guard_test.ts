import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test community creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test creation as owner
    let block = chain.mineBlock([
      Tx.contractCall('game-guard', 'create-community', 
        [types.ascii("Test Community"), types.uint(10)], 
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Test creation as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'create-community',
        [types.ascii("Failed Community"), types.uint(10)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test member management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Create community first
    let block = chain.mineBlock([
      Tx.contractCall('game-guard', 'create-community',
        [types.ascii("Test Community"), types.uint(10)],
        deployer.address
      )
    ]);
    
    // Add member
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'add-member',
        [types.uint(1), types.principal(wallet1.address)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Update member role
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'update-member-role',
        [types.uint(1), types.principal(wallet1.address), types.uint(2)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try adding member as non-admin (should fail)
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'add-member',
        [types.uint(1), types.principal(wallet2.address)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100);
  }
});
