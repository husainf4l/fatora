import { $Enums } from '../../generated/prisma';

// Use Prisma's generated Role enum
export type Role = $Enums.Role;

export interface User {
  id: string;
  email: string;
  password: string;
  firstName: string | null;
  lastName: string | null;
  role: Role;
  createdAt: Date;
  updatedAt: Date;
}

export type UserWithoutPassword = Omit<User, 'password'>;